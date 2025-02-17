// Ensure this file is imported as type="module" in index.html

import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore, collection, doc, getDoc, setDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';

const texmf_local = ['./texmf', './.texmf'];

const paths_list = Array.from(document.head.getElementsByTagName('link'))
    .filter(link => link.rel === 'busytex')
    .map(link => [link.id, link.href]);

const texlive_data_packages_js = paths_list
    .filter(([id, href]) => id.startsWith('texlive_'))
    .map(([id, href]) => href);

const paths = { ...Object.fromEntries(paths_list), texlive_data_packages_js };

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

// Add these state variables at the top with other declarations
let lastSavedContent = { tex: '', bib: '' };
let isOffline = false;

let currentFile = "main.tex";

// Keep only the global declaration at the top of the file
let fileStructure = {
    "Project": {
        "main.tex": "% Your LaTeX content here",
        "references.bib": "@article{example}",
        "chapters": {
            "chapter1.tex": "\\section{Chapter 1}",
            "chapter2.tex": "\\section{Chapter 2}"
        }
    }
};

document.getElementById("compile-button").addEventListener("click", onclick_);

async function fetchEditorContent() {
    try {
        const docRef = doc(collection(db, "documents"), "default");
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            const data = docSnap.data();
            lastSavedContent = {
                tex: data.tex || '',
                bib: data.bib || ''
            };
            
            return {
                texContent: data.tex ? decodeURIComponent(escape(atob(data.tex))) : "",
                bibContent: data.bib ? decodeURIComponent(escape(atob(data.bib))) : ""
            };
        }
        return { texContent: "", bibContent: "" };
    } catch (error) {
        console.error("Failed to fetch content:", error);
        isOffline = true;
        return { texContent: "", bibContent: "" };
    }
}

async function saveEditorContent() {
    if (!texEditor || !bibEditor || isOffline) {
        return;
    }

    try {
        const newTexContent = btoa(unescape(encodeURIComponent(texEditor.getValue())));
        const newBibContent = btoa(unescape(encodeURIComponent(bibEditor.getValue())));

        // Only save if content has changed
        if (newTexContent === lastSavedContent.tex && newBibContent === lastSavedContent.bib) {
            return;
        }

        await setDoc(doc(db, "documents", "default"), {
            tex: newTexContent,
            bib: newBibContent,
            lastModified: new Date().toISOString()
        });

        lastSavedContent = {
            tex: newTexContent,
            bib: newBibContent
        };

        console.log("Document saved successfully!");
    } catch (error) {
        console.error("Error saving document:", error);
        isOffline = true;
    }
}

// Auto-save function (waits 30 seconds after last change)
function startAutoSave() {
    clearTimeout(autoSaveTimeout); // Prevent multiple saves
    autoSaveTimeout = setTimeout(saveEditorContent, 5000); // Auto-save after 5 seconds
}

// Debouncing function for auto-save (waits for user to stop typing)
function startAutoSaveDebounced() {
    clearTimeout(autoSaveTimeout);
    autoSaveTimeout = setTimeout(() => {
        startAutoSave();  // Call the actual auto-save function after a delay
    }, 500);  // Adjust delay (500ms = waits for user to stop typing)
}

async function loadFile(filename, content) {
    try {
        if (filename.endsWith(".tex")) {
            texEditor.setValue(content);
            currentFile = filename;
            // Save to Firebase
            await saveEditorContent();
        } else if (filename.endsWith(".bib")) {
            bibEditor.setValue(content);
            // Save to Firebase
            await saveEditorContent();
        }
    } catch (error) {
        console.error("Error loading file:", error);
    }
}

async function onclick_() {
    if (compileButton.classList.contains('compiling')) {
        // Handle stop compilation
        terminate();
        compileButton.classList.remove('compiling');
        compileButton.innerText = "Compile";
        if (spinnerElement) {
            spinnerElement.style.display = 'none';
        }
        return;
    }

    // Start compilation
    compileButton.classList.add('compiling');
    compileButton.innerText = "Stop compilation";
    
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
        if (!use_auto) {
            data_packages_js = [];
            for (const [key, checkbox] of Object.entries(ubuntuPackageCheckboxes)) {
                if (checkbox.checked)
                    data_packages_js.push(texlive_data_packages_js.find(path => path.includes(key)));
            }
        }

        let tic = performance.now();
        const reload = worker == null;
        if (use_worker) {
            if (reload) worker = new Worker(paths.busytex_worker_js);
        } else if (reload) {
            worker = {
                async postMessage({ files, main_tex_path, bibtex, preload, verbose, busytex_js, busytex_wasm, texmf_local, preload_data_packages_js, data_packages_js }) {
                    if (busytex_wasm && busytex_js && preload_data_packages_js) {
                        this.pipeline = new Promise((resolve, reject) => {
                            let script = document.createElement('script');
                            script.src = busytex_pipeline_js;
                            script.onload = resolve;
                            script.onerror = reject;
                            document.head.appendChild(script);
                        }).then(_ => Promise.resolve(new BusytexPipeline(
                            busytex_js, busytex_wasm, data_packages_js, preload_data_packages_js,
                            texmf_local, msg => this.onmessage({ data: { log: msg } }),
                            preload, BusytexPipeline.ScriptLoaderDefault
                        )));
                    } else if (files && this.pipeline) {
                        const pipeline = await this.pipeline;
                        const pdf = await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js);
                        this.onmessage({ data: { pdf } });
                    }
                },
                terminate() {
                    this.onmessage({ data: { log: 'Terminating dummy worker' } });
                }
            };
        }

    worker.onmessage = ({ data : {pdf, log, print} }) =>
    {
        if(pdf)
        {
            previewElement.src = URL.createObjectURL(new Blob([pdf], {type: 'application/pdf'}));
            elapsedElement.innerText = ((performance.now() - tic) / 1000).toFixed(2) + ' sec';
            if (spinnerElement) {
                spinnerElement.style.display = 'none';   // Hide spinner
            }
            compileButton.classList.remove('compiling');
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

    function terminate() {
        if (worker !== null) worker.terminate();
        worker = null;
    }

function renderFileExplorer(container, structure) {
    container.innerHTML = "";
    const ul = document.createElement("ul");
    ul.className = "file-tree";

    function createTree(obj, parentUl) {
        for (const key in obj) {
            const li = document.createElement("li");

            if (typeof obj[key] === "object") {
                // Folder structure remains the same with just chevron
                const itemContent = document.createElement("div");
                itemContent.className = "file-item";
                
                const chevron = document.createElement("span");
                chevron.className = "codicon codicon-chevron-right";
                
                const label = document.createElement("span");
                label.textContent = key;
                
                itemContent.appendChild(chevron);
                itemContent.appendChild(label);
                
                const subUl = document.createElement("ul");
                subUl.style.display = "none";
                
                li.appendChild(itemContent);
                li.appendChild(subUl);
                
                itemContent.addEventListener("click", (e) => {
                    e.stopPropagation();
                    subUl.style.display = subUl.style.display === "none" ? "block" : "none";
                    itemContent.classList.toggle("expanded");
                    chevron.style.transform = itemContent.classList.contains("expanded")
                        ? "rotate(90deg)"
                        : "rotate(0)";
                });
                
                createTree(obj[key], subUl);

                itemContent.addEventListener("contextmenu", (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    showContextMenu(e, true);
                });
                
                li.addEventListener("contextmenu", (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    showContextMenu(e, true);
                });
                
                li.className = "folder";  // Make sure folder class is on the li
            } else {
                // File structure with proper VS Code codicon
                const itemContent = document.createElement("div");
                itemContent.className = "file-item";
                
                const fileIcon = document.createElement("span");
                // Use proper VS Code file icons based on extension
                if (key.endsWith('.tex')) {
                    fileIcon.className = "codicon codicon-file-code";
                } else if (key.endsWith('.bib')) {
                    fileIcon.className = "codicon codicon-references";
                } else {
                    fileIcon.className = "codicon codicon-file";
                }
                
                const label = document.createElement("span");
                label.textContent = key;
                
                itemContent.appendChild(fileIcon);
                itemContent.appendChild(label);
                itemContent.addEventListener("click", () => loadFile(key, obj[key]));
                
                li.appendChild(itemContent);
            }
            
            parentUl.appendChild(li);
        }
    }

    createTree(structure, ul);
    container.appendChild(ul);
}

// Add this function after your existing code
function showContextMenu(e, isFolder) {
    e.preventDefault();
    
    console.log('Right-clicked element:', e.target);
    console.log('Parent elements:', e.target.parentElement);
    
    const explorer = document.querySelector('.file-explorer');
    explorer.classList.add('context-active');
    
    // Try to find folder element more reliably
    const folderElement = e.target.closest('.folder') || 
                         e.target.parentElement.closest('.folder') ||
                         e.composedPath().find(el => el.classList?.contains('folder'));
                         
    console.log('Found folder element:', folderElement);
    
    if (!folderElement) {
        console.error('Could not find folder element');
        return;
    }
    
    const folderItemSpan = folderElement.querySelector('.file-item span:last-child');
    
    if (!folderItemSpan) {
        console.error('Could not find folder label');
        return;
    }
    
    const folderPath = folderItemSpan.textContent;
    console.log('Folder path:', folderPath);
    
    // Remove any existing context menus
    const existingMenu = document.querySelector('.context-menu');
    if (existingMenu) {
        existingMenu.remove();
    }

    if (isFolder) {
        const menu = document.createElement('div');
        menu.className = 'context-menu';
        
        const uploadItem = document.createElement('div');
        uploadItem.className = 'context-menu-item';
        uploadItem.innerHTML = '<span class="codicon codicon-cloud-upload"></span>Upload File';
        
        uploadItem.onclick = () => {
            const input = document.createElement('input');
            input.type = 'file';
            
            // Use the captured folderPath in the onchange handler
            input.onchange = (inputEvent) => {
                const file = inputEvent.target.files[0];
                if (file) {
                    // Now we can safely use the captured folderPath
                    fileStructure.Project[folderPath][file.name] = "// New file content";
                    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                }
                explorer.classList.remove('context-active');
                menu.remove();
            };
            input.click();
        };
        
        menu.appendChild(uploadItem);
        menu.style.left = `${e.pageX}px`;
        menu.style.top = `${e.pageY}px`;
        document.body.appendChild(menu);
    }
}

// Update the click handler to remove active class when clicking outside
document.addEventListener('click', (e) => {
    if (!e.target.closest('.context-menu')) {
        const menu = document.querySelector('.context-menu');
        const explorer = document.querySelector('.file-explorer');
        if (menu) {
            menu.remove();
            explorer.classList.remove('context-active');
        }
    }
});

// Add handler to remove active class when mouse leaves explorer
document.querySelector('.file-explorer').addEventListener('mouseleave', (e) => {
    if (!document.querySelector('.context-menu')) {
        e.currentTarget.classList.remove('context-active');
    }
});

// Initialize Monaco Editor with Firebase content
require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.21.2/min/vs' }});
require(['vs/editor/editor.main'], async function() {
    const { texContent, bibContent } = await fetchEditorContent();

    // Update the global fileStructure with fetched content
    fileStructure.Project["main.tex"] = texContent || "% Your LaTeX content here";
    fileStructure.Project["references.bib"] = bibContent || "@article{example}";

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

    // Create editors with automaticLayout: true
    texEditor = monaco.editor.create(document.getElementById('tex-editor'), {
        value: texContent,
        language: 'latex',
        theme: 'vs-dark',
        wordWrap: 'on',
        automaticLayout: true  // Enable automatic layout updates
    });

    bibEditor = monaco.editor.create(document.getElementById('bib-editor'), {
        value: bibContent,
        language: 'bibtex',
        theme: 'vs-dark',
        wordWrap: 'on',
        automaticLayout: true  // Enable automatic layout updates
    });

    // Auto-save when users type
    texEditor.onDidChangeModelContent(startAutoSaveDebounced);
    bibEditor.onDidChangeModelContent(startAutoSaveDebounced);

    // Add after editor initialization
    const editorContainer = document.getElementById('editor-container');
    const previewContainer = document.getElementById('preview-container');

    // Handle editor focus
    editorContainer.addEventListener('mouseenter', () => {
        editorContainer.style.zIndex = '2';
        previewContainer.style.zIndex = '1';
    });

    // Handle preview focus
    previewContainer.addEventListener('mouseenter', () => {
        previewContainer.style.zIndex = '2';
        editorContainer.style.zIndex = '1';
    });

    // Set initial focus to editor
    texEditor.focus();

    // Initialize file explorer after editors are created
    const explorerContainer = document.getElementById("file-tree");
    renderFileExplorer(explorerContainer, fileStructure);

    // Update file content when editor content changes
    texEditor.onDidChangeModelContent(() => {
        if (currentFile.endsWith(".tex")) {
            fileStructure.Project[currentFile] = texEditor.getValue();
        }
        startAutoSaveDebounced();
    });

    bibEditor.onDidChangeModelContent(() => {
        if (currentFile.endsWith(".bib")) {
            fileStructure.Project[currentFile] = bibEditor.getValue();
        }
        startAutoSaveDebounced();
    });
});