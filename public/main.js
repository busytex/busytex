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
        // Separate folders and files
        const entries = Object.entries(obj);
        const folders = entries.filter(([_, value]) => typeof value === 'object');
        const files = entries.filter(([_, value]) => typeof value !== 'object');
        
        // Process folders first
        for (const [key, value] of folders) {
            const li = document.createElement("li");
            li.className = "folder";
            
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
            
            // Add context menu for folders
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
            
            createTree(value, subUl);
            parentUl.appendChild(li);
        }
        
        // Then process files
        for (const [key, value] of files) {
            const li = document.createElement("li");
            const itemContent = document.createElement("div");
            itemContent.className = "file-item";
            
            const fileIcon = document.createElement("span");
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
            itemContent.addEventListener("click", () => loadFile(key, value));
            
            // Add context menu for files
            itemContent.addEventListener("contextmenu", (e) => {
                e.preventDefault();
                e.stopPropagation();
                showContextMenu(e, false);
            });
            
            li.addEventListener("contextmenu", (e) => {
                e.preventDefault();
                e.stopPropagation();
                showContextMenu(e, false);
            });
            
            li.appendChild(itemContent);
            parentUl.appendChild(li);
        }
    }

    createTree(structure, ul);
    container.appendChild(ul);
}

// Add this function after your existing code
function showContextMenu(e, isFolder) {
    e.preventDefault();
    
    const explorer = document.querySelector('.file-explorer');
    explorer.classList.add('context-active');
    
    // Remove any existing context menus
    const existingMenu = document.querySelector('.context-menu');
    if (existingMenu) {
        existingMenu.remove();
    }

    // Find the clicked element
    const targetElement = e.target.closest('.file-item');
    const folderElement = e.target.closest('.folder');
    
    if (!targetElement) return;

    const menu = document.createElement('div');
    menu.className = 'context-menu';

    // Update the upload item section in showContextMenu
    if (isFolder) {
        const folderPath = targetElement.querySelector('span:last-child').textContent;
        
        const uploadItem = document.createElement('div');
        uploadItem.className = 'context-menu-item';
        uploadItem.innerHTML = '<span class="codicon codicon-cloud-upload"></span>Upload File';
        
        uploadItem.onclick = () => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = '*';

            input.onchange = (inputEvent) => {
                const file = inputEvent.target.files[0];
                if (file) {
                    const states = getFolderStates();
                    
                    // Update the file structure at the correct path
                    if (folderPath === "Project") {
                        fileStructure.Project[file.name] = "// Empty file content";
                    } else if (fileStructure.Project[folderPath]) {
                        fileStructure.Project[folderPath][file.name] = "// Empty file content";
                    }
                    
                    // Ensure the target folder is expanded in the states
                    states.set(folderPath, true);
                    
                    // Re-render and restore states with the target folder expanded
                    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                    applyFolderStates(states);
                }
                explorer.classList.remove('context-active');
                menu.remove();
            };
            input.click();
        };
        
        menu.appendChild(uploadItem);
        
        const deleteItem = document.createElement('div');
        deleteItem.className = 'context-menu-item';
        deleteItem.innerHTML = '<span class="codicon codicon-trash"></span>Delete Folder';
        
        deleteItem.onclick = () => {
            const folderContent = fileStructure.Project[folderPath];
            if (Object.keys(folderContent).length === 0) {
                const states = getFolderStates();
                delete fileStructure.Project[folderPath];
                renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                applyFolderStates(states);
            } else {
                alert(`Folder "${folderPath}" is not empty`);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };

        menu.appendChild(deleteItem);

        const renameItem = document.createElement('div');
        renameItem.className = 'context-menu-item';
        renameItem.innerHTML = '<span class="codicon codicon-edit"></span>Rename';
        
        renameItem.onclick = () => {
            const newName = prompt("Enter new folder name:", folderPath);
            if (newName && newName !== folderPath) {
                renameFileOrFolder(folderPath, newName, true);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        
        menu.appendChild(renameItem);
    } else {
        // File context menu
        const fileName = targetElement.querySelector('span:last-child').textContent;
        
        const renameItem = document.createElement('div');
        renameItem.className = 'context-menu-item';
        renameItem.innerHTML = '<span class="codicon codicon-edit"></span>Rename';
        
        renameItem.onclick = () => {
            const newName = prompt("Enter new file name:", fileName);
            if (newName && newName !== fileName) {
                renameFileOrFolder(fileName, newName, false);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        
        menu.appendChild(renameItem);

        const deleteItem = document.createElement('div');
        deleteItem.className = 'context-menu-item';
        deleteItem.innerHTML = '<span class="codicon codicon-trash"></span>Delete File';
        
        deleteItem.onclick = () => {
            const states = getFolderStates();
            for (const folder in fileStructure.Project) {
                if (typeof fileStructure.Project[folder] === 'object' && 
                    fileStructure.Project[folder].hasOwnProperty(fileName)) {
                    delete fileStructure.Project[folder][fileName];
                    break;
                }
            }
            renderFileExplorer(document.getElementById('file-tree'), fileStructure);
            applyFolderStates(states);
            explorer.classList.remove('context-active');
            menu.remove();
        };

        menu.appendChild(deleteItem);
    }

    menu.style.left = `${e.pageX}px`;
    menu.style.top = `${e.pageY}px`;
    document.body.appendChild(menu);
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

// Add these functions before renderFileExplorer

function getFolderStates() {
    const states = new Map();
    const folders = document.querySelectorAll('.folder');
    
    folders.forEach(folder => {
        const folderName = folder.querySelector('.file-item span:last-child').textContent;
        const isExpanded = folder.querySelector('.file-item').classList.contains('expanded');
        states.set(folderName, isExpanded);
    });
    
    return states;
}

function applyFolderStates(states) {
    const folders = document.querySelectorAll('.folder');
    
    folders.forEach(folder => {
        const folderName = folder.querySelector('.file-item span:last-child').textContent;
        if (states.get(folderName)) {
            const itemContent = folder.querySelector('.file-item');
            const subUl = folder.querySelector('ul');
            const chevron = folder.querySelector('.codicon-chevron-right');
            
            itemContent.classList.add('expanded');
            subUl.style.display = 'block';
            chevron.style.transform = 'rotate(90deg)';
        }
    });
}

// Add this function after your existing code
function renameFileOrFolder(oldPath, newName, isFolder) {
    const states = getFolderStates();
    
    if (isFolder) {
        // Rename folder
        const folderContent = fileStructure.Project[oldPath];
        delete fileStructure.Project[oldPath];
        fileStructure.Project[newName] = folderContent;
    } else {
        // Rename file
        for (const folder in fileStructure.Project) {
            if (typeof fileStructure.Project[folder] === 'object' && 
                fileStructure.Project[folder].hasOwnProperty(oldPath)) {
                const content = fileStructure.Project[folder][oldPath];
                delete fileStructure.Project[folder][oldPath];
                fileStructure.Project[folder][newName] = content;
                break;
            }
        }
    }
    
    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
    applyFolderStates(states);
}

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