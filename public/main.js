import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore, collection, doc, getDoc, setDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';

const texmf_local = ['./texmf', './.texmf'];

const paths_list = Array.from(document.head.getElementsByTagName('link')).filter(link => link.rel == 'busytex').map(link => [link.id, link.href]);
const texlive_data_packages_js = paths_list.filter(([id, href]) => id.startsWith('texlive_')).map(([id, href]) => href);
const paths = { ...Object.fromEntries(paths_list), texlive_data_packages_js : texlive_data_packages_js };

let worker = null;
let texEditor = null;
let bibEditor = null;

const workerCheckbox = document.getElementById('worker');
const preloadCheckbox = document.getElementById('preload');
const verboseSelect = document.getElementById('verbose');
const driverSelect = document.getElementById('tex_driver');
const bibtexCheckbox = document.getElementById('bibtex');
const autoCheckbox = document.getElementById('checked_texlive_auto');
const previewElement = document.getElementById('preview');
const elapsedElement = document.getElementById('elapsed');
const ubuntuPackageCheckboxes = {
    recommended: document.getElementById('checked_texlive_ubuntu_recommended'),
    extra: document.getElementById('checked_texlive_ubuntu_extra'),
    science: document.getElementById('checked_texlive_ubuntu_science')
};
const compileButton = document.getElementById("compile-button");
const spinnerElement = document.getElementById('spinner');

// Store auto-save timeout
let autoSaveTimeout;

document.getElementById("compile-button").addEventListener("click", onclick_);

async function fetchEditorContent() {
    const docRef = doc(collection(db, "documents"), "default");
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
        const data = docSnap.data();
        return {
            texContent: data.tex.replace(/\\n/g, "\n").replace(/\\r/g, "\r"), // Convert stored `\n` into actual newlines
            bibContent: data.bib.replace(/\\n/g, "\n").replace(/\\r/g, "\r")
        };
    } else {
        console.error("No such document!");
        return { texContent: '', bibContent: '' };
    }
}

async function saveEditorContent() {
    if (!texEditor || !bibEditor) {
        console.error("Editors are not initialized yet!");
        return;
    }

    // Get content from Monaco Editor and properly escape newlines and carriage returns
    const texContent = texEditor.getValue().replace(/\n/g, "\\n").replace(/\r/g, "\\r");
    const bibContent = bibEditor.getValue().replace(/\n/g, "\\n").replace(/\r/g, "\\r");

    try {
        await setDoc(doc(db, "documents", "default"), {
            tex: texContent,
            bib: bibContent
        });
        console.log("LaTeX document saved successfully!");
    } catch (error) {
        console.error("Error saving LaTeX document:", error);
    }
}

// Auto-save function (waits 30 seconds after last change)
function startAutoSave() {
    clearTimeout(autoSaveTimeout); // Prevent multiple saves
    autoSaveTimeout = setTimeout(saveEditorContent, 30000); // Auto-save after 30 seconds
}

// Debouncing function for auto-save (waits for user to stop typing)
function startAutoSaveDebounced() {
    clearTimeout(autoSaveTimeout);
    autoSaveTimeout = setTimeout(() => {
        startAutoSave();  // Call the actual auto-save function after a delay
    }, 500);  // Adjust delay (500ms = waits for user to stop typing)
}

async function onclick_() {
    compileButton.disabled = true; 
    compileButton.innerText = "Compiling ...";

    if (spinnerElement) {
        spinnerElement.style.display = 'block';
    }

    const use_worker = workerCheckbox.checked;
    const use_preload = preloadCheckbox.checked;
    const use_verbose = verboseSelect.value;
    const use_driver = driverSelect.value;
    const use_bibtex = bibtexCheckbox.checked;
    const use_auto = autoCheckbox.checked;

    let data_packages_js = null;
    if(!use_auto)
    {
        data_packages_js = [];
        for(const [key, checkbox] of Object.entries(ubuntuPackageCheckboxes))
        {
            if(checkbox.checked)
                data_packages_js.push(texlive_data_packages_js.find(path => path.includes(key)));
        }
    }

    let tic = 0;
    
    const reload = worker == null;
    if(use_worker)
    {
        if(reload)
            worker = new Worker(paths.busytex_worker_js);
    }
    else if(reload)
    {
        worker = 
        {
            async postMessage({files, main_tex_path, bibtex, preload, verbose, busytex_js, busytex_wasm, texmf_local,  preload_data_packages_js, data_packages_js})
            {
                if(busytex_wasm && busytex_js && preload_data_packages_js)
                {
                    this.pipeline = new Promise(function (resolve, reject)
                    {
                        let s = document.createElement('script');
                        s.src = busytex_pipeline_js;
                        s.onload = resolve;
                        s.onerror = reject;
                        self.document.head.appendChild(s);
                    }).then(_ => Promise.resolve(new BusytexPipeline(busytex_js, busytex_wasm, data_packages_js, preload_data_packages_js, texmf_local, msg => this.onmessage({data: {log : msg}}), preload, BusytexPipeline.ScriptLoaderDefault)));
                }

                else if(files && this.pipeline)
                {
                    const pipeline = await this.pipeline;
                    const pdf = await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js)
                    this.onmessage({data : {pdf : pdf}});
                }
            },

            terminate()
            {
                this.onmessage({data : {log : 'Terminating dummy worker'}});
            }
        }
    }

    worker.onmessage = ({ data : {pdf, log, print} }) =>
    {
        if(pdf)
        {
            previewElement.src = URL.createObjectURL(new Blob([pdf], {type: 'application/pdf'}));
            elapsedElement.innerText = ((performance.now() - tic) / 1000).toFixed(2) + ' sec';
            if (spinnerElement) {
                spinnerElement.style.display = 'none';
            }
            compileButton.disabled = false;
            compileButton.innerText = "Compile";
            console.log('Compilation successful');
        }

        if(print)
        {
            console.log(print);
        }
    }
    
    if(reload)
        worker.postMessage({...paths, texmf_local : texmf_local, preload_data_packages_js : paths.texlive_data_packages_js.slice(0, 1), data_packages_js : paths.texlive_data_packages_js});

    tic = performance.now();
    const tex = texEditor.getValue();
    const bib = bibEditor.getValue();
    const files = [{path : 'example.tex', contents : tex}, {path : 'example.bib', contents : bib}];
    worker.postMessage({files : files, main_tex_path : 'example.tex', verbose : use_verbose, bibtex : use_bibtex, driver : use_driver, data_packages_js : data_packages_js});
}

function terminate()
{
    if(worker != null)
        worker.terminate();
    worker = null;
}

// Initialize Monaco Editor with Firebase content
require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.21.2/min/vs' }});
require(['vs/editor/editor.main'], async function() {
    const { texContent, bibContent } = await fetchEditorContent();

    monaco.languages.register({ id: 'latex' });

    monaco.languages.setMonarchTokensProvider('latex', {
        tokenizer: {
            root: [
                [/\\[a-zA-Z]+/, 'keyword'],
                [/%.*/, 'comment'],
                [/\{[^}]*\}/, 'string'],
                [/\[[^\]]*\]/, 'string'],
                [/\$[^$]*\$/, 'string'],
            ]
        }
    });

    // Initialize Monaco Editor
    texEditor = monaco.editor.create(document.getElementById('tex-editor'), {
        value: texContent,
        language: 'latex',
        theme: 'vs-dark',
        wordWrap: "on"
    });

    bibEditor = monaco.editor.create(document.getElementById('bib-editor'), {
        value: bibContent,
        language: 'latex',
        theme: 'vs-dark',
        wordWrap: "on"
    });

    // ✅ Add Debounced ResizeObserver to Prevent Loops
    let resizeTimeout;
    window.addEventListener("resize", () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            texEditor.layout();
            bibEditor.layout();
        }, 300);  // Adjust delay as needed (300ms is a good default)
    });

    // Auto-save when users type
    texEditor.onDidChangeModelContent(startAutoSaveDebounced);
    bibEditor.onDidChangeModelContent(startAutoSaveDebounced);
});