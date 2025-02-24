// Ensure this file is imported as type="module" in index.html

import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
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

// Update the initial structure declaration
let projectStructure = { Projects: {} }; // Holds all projects
let fileStructure = {};  // Holds individual project file mappings
let mainTexFile = "";
let currentProject = null;  // Add this to track the current project

document.getElementById("compile-button").addEventListener("click", onclick_);

async function createProjectInFirestore(projectName) {
    const projectRef = doc(collection(db, "projects"), projectName);

    // Check if the project already exists
    const projectSnap = await getDoc(projectRef);
    if (projectSnap.exists()) {
        alert("A project with this name already exists!");
        return;
    }

    const projectData = {
        name: projectName,
        createdAt: new Date().toISOString(),
        gitPath: `TexWaller-Projects/${projectName}`,
        fileStructure: {},
        currentTex: "\\documentclass{article}\n\\begin{document}\n\\end{document}",
        currentBib: "",
        mainTexFile: "main.tex"
    };

    await setDoc(projectRef, projectData);
    console.log(`Project '${projectName}' saved in Firestore`);
}

async function loadProjectsFromFirestore() {
    try {
        const projectsRef = collection(db, "projects");
        const querySnapshot = await getDocs(projectsRef);

        // Initialize the structure with Projects object first
        fileStructure = { Projects: {} };

        querySnapshot.forEach((doc) => {
            const project = doc.data();
            // Now we can safely set properties on fileStructure.Projects
            fileStructure.Projects[project.name] = project.fileStructure || {};
            if (!currentProject) {
                currentProject = project.name;
                mainTexFile = project.mainTexFile || "main.tex";
            }
        });

        renderFileExplorer(document.getElementById("file-tree"), fileStructure);
    } catch (error) {
        console.error("Error loading projects:", error);
        alert("Failed to load projects from Firestore");
    }
}

// Add this new function to update mainTexFile in Firestore
async function updateMainTexFileInFirestore(projectName, newMainTexFile) {
    try {
        const projectRef = doc(collection(db, "projects"), projectName);
        await updateDoc(projectRef, {
            mainTexFile: newMainTexFile
        });
        console.log(`Main tex file updated to ${newMainTexFile} in project ${projectName}`);
    } catch (error) {
        console.error("Error updating main tex file:", error);
    }
}

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
            fileStructure.Projects[currentFile] = texEditor.getValue();  // Changed from Project
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

    // Ensure "Projects" root exists before rendering
    if (!structure.Projects) {
        structure.Projects = {};
    }

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
            itemContent.draggable = true;
            
            // Add drag event listeners for folders
            itemContent.addEventListener('dragstart', (e) => {
                e.stopPropagation();
                e.dataTransfer.setData('text/plain', JSON.stringify({
                    path: getItemPath(itemContent),
                    isFolder: true
                }));
                itemContent.classList.add('dragging');
            });
            
            itemContent.addEventListener('dragend', () => {
                itemContent.classList.remove('dragging');
            });
            
            itemContent.addEventListener('dragover', (e) => {
                e.preventDefault();
                e.stopPropagation();
                itemContent.classList.add('drag-over');
            });
            
            itemContent.addEventListener('dragleave', () => {
                itemContent.classList.remove('drag-over');
            });
            
            itemContent.addEventListener('drop', (e) => {
                e.preventDefault();
                e.stopPropagation();
                itemContent.classList.remove('drag-over');
                
                const data = JSON.parse(e.dataTransfer.getData('text/plain'));
                const targetPath = getItemPath(itemContent);
                
                // Prevent dropping into descendant
                if (data.isFolder && isDescendant(data.path, targetPath)) {
                    return;
                }
                
                // Move the item
                moveItem(data.path, targetPath, data.isFolder);
            });
            
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
            itemContent.draggable = true;
            
            // Add drag event listeners for files
            itemContent.addEventListener('dragstart', (e) => {
                e.stopPropagation();
                e.dataTransfer.setData('text/plain', JSON.stringify({
                    path: getItemPath(itemContent),
                    isFolder: false
                }));
                itemContent.classList.add('dragging');
            });
            
            itemContent.addEventListener('dragend', () => {
                itemContent.classList.remove('dragging');
            });
            
            const fileIcon = document.createElement("span");
            if (key.endsWith('.tex')) {
                fileIcon.className = "codicon codicon-file-code";
                if (key === mainTexFile && fileStructure.Projects.hasOwnProperty(key)) {
                    itemContent.classList.add('main-tex');
                }
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

    // Add Create Project item after the tree
    const createProjectItem = document.createElement("div");
    createProjectItem.className = "create-project-item";
    createProjectItem.innerHTML = `
        <span class="codicon codicon-new-folder"></span>
        <span>Create Project</span>
    `;
    
    // Update the create project click handler
    createProjectItem.addEventListener("click", async () => {
        const newProjectName = prompt("Enter project name:");
        if (!newProjectName || newProjectName.trim() === "") return;
    
        try {
            await createProjectInFirestore(newProjectName.trim());
            const states = getFolderStates();
            
            // Add new project as a folder under Projects
            fileStructure.Projects[newProjectName] = fileStructure.Projects[newProjectName] || {};            

            // Make sure the Projects folder is expanded
            states.set('Projects', true);
            
            renderFileExplorer(document.getElementById('file-tree'), fileStructure);
            applyFolderStates(states);
    
            alert(`Project '${newProjectName}' created successfully!`);
        } catch (error) {
            console.error("Error creating project:", error);
            alert("Failed to create project. Please try again.");
        }
    });
    
    container.appendChild(ul);
    container.appendChild(createProjectItem);

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

    // Update the folder handling section in showContextMenu
    if (isFolder) {
        const folderPath = targetElement.querySelector('span:last-child').textContent;
        
        // Add create folder option
        const createFolderItem = document.createElement('div');
        createFolderItem.className = 'context-menu-item';
        createFolderItem.innerHTML = '<span class="codicon codicon-new-folder"></span>Create Folder';
        
        createFolderItem.onclick = () => {
            const newFolderName = prompt("Enter folder name:");
            if (newFolderName) {
                const states = getFolderStates();
                
                // Add new folder to the structure
                if (folderPath === "Projects") {  // Changed from Project
                    fileStructure.Projects[newFolderName] = {};  // Changed from Project
                } else if (fileStructure.Projects[folderPath]) {  // Changed from Project
                    fileStructure.Projects[folderPath][newFolderName] = {};
                }
                
                // Ensure parent folder is expanded
                states.set(folderPath, true);
                
                renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                applyFolderStates(states);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        
        menu.appendChild(createFolderItem);
        
        // Add existing upload item after create folder
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
                    if (folderPath === "Projects") {  // Changed from Project
                        fileStructure.Projects[file.name] = "// Empty file content";  // Changed from Project
                    } else if (fileStructure.Projects[folderPath]) {  // Changed from Project
                        fileStructure.Projects[folderPath][file.name] = "// Empty file content";
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
        
        // Add delete option for all folders (including root)
        const deleteItem = document.createElement('div');
        deleteItem.className = 'context-menu-item';
        deleteItem.innerHTML = '<span class="codicon codicon-trash"></span>Delete Folder';
        
        deleteItem.onclick = () => {
            const folderContent = fileStructure[folderPath];
            if (Object.keys(folderContent).length === 0) {
                const states = getFolderStates();
                delete fileStructure[folderPath];
                // If root folder was deleted, create a new empty root
                if (folderPath === "Projects") {  // Changed from Project
                    fileStructure["New Project"] = {};
                }
                renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                applyFolderStates(states);
            } else {
                alert(`Folder "${folderPath}" is not empty`);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        menu.appendChild(deleteItem);

        // Add rename option for all folders (including root)
        const renameItem = document.createElement('div');
        renameItem.className = 'context-menu-item';
        renameItem.innerHTML = '<span class="codicon codicon-edit"></span>Rename';
        
        renameItem.onclick = () => {
            const newName = prompt("Enter new folder name:", folderPath);
            if (newName && newName !== folderPath) {
                const states = getFolderStates();
                const folderContent = fileStructure[folderPath];
                delete fileStructure[folderPath];
                fileStructure[newName] = folderContent;
                renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                applyFolderStates(states);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        menu.appendChild(renameItem);
    } else {
        // File context menu
        const fileName = targetElement.querySelector('span:last-child').textContent;
        const isRootTexFile = fileName.endsWith('.tex') && 
                             fileStructure.Projects.hasOwnProperty(fileName);  // Changed from Project
        
        // Add "Set as Main Tex File" option only for root .tex files
        if (isRootTexFile) {
            const setMainTexItem = document.createElement('div');
            setMainTexItem.className = 'context-menu-item main-tex-option';
            const isCurrentMain = fileName === mainTexFile;
            
            setMainTexItem.innerHTML = `
                <span class="codicon codicon-file-code"></span>
                ${isCurrentMain ? 'Main Tex File' : 'Set as Main Tex File'}
            `;
            
            if (!isCurrentMain) {
                setMainTexItem.onclick = async () => {
                    const states = getFolderStates();
                    mainTexFile = fileName;
                    await updateMainTexFileInFirestore(currentProject, fileName);  // Add this line
                    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                    applyFolderStates(states);  // Restore states after re-render
                    explorer.classList.remove('context-active');
                    menu.remove();
                };
                menu.appendChild(setMainTexItem);
            }
        }
        
        // Add existing menu items (rename, delete, etc.)
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
            let fileDeleted = false;

            // Check if file is directly in Projects folder
            if (fileStructure.Projects.hasOwnProperty(fileName)) {  // Changed from Project
                delete fileStructure.Projects[fileName];  // Changed from Project
                fileDeleted = true;
            } else {
                // Check in subfolders
                for (const folder in fileStructure.Projects) {  // Changed from Project
                    if (typeof fileStructure.Projects[folder] === 'object' &&  // Changed from Project
                        fileStructure.Projects[folder].hasOwnProperty(fileName)) {  // Changed from Project
                        delete fileStructure.Projects[folder][fileName];  // Changed from Project
                        fileDeleted = true;
                        break;
                    }
                }
            }

            if (fileDeleted) {
                renderFileExplorer(document.getElementById('file-tree'), fileStructure);
                applyFolderStates(states);
            }
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
        const isExpanded = folder.querySelector('ul').style.display === 'block';
        states.set(folderName, isExpanded);
    });
    
    return states;
}

function applyFolderStates(states) {
    const folders = document.querySelectorAll('.folder');
    
    folders.forEach(folder => {
        const folderName = folder.querySelector('.file-item span:last-child').textContent;
        const shouldBeExpanded = states.get(folderName);
        
        if (shouldBeExpanded) {
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
        const folderContent = fileStructure.Projects[oldPath];  // Changed from Project
        delete fileStructure.Projects[oldPath];  // Changed from Project
        fileStructure.Projects[newName] = folderContent;  // Changed from Project
    } else {
        // Rename file
        for (const folder in fileStructure.Projects) {  // Changed from Project
            if (typeof fileStructure.Projects[folder] === 'object' &&  // Changed from Project
                fileStructure.Projects[folder].hasOwnProperty(oldPath)) {  // Changed from Project
                const content = fileStructure.Projects[folder][oldPath];  // Changed from Project
                delete fileStructure.Projects[folder][oldPath];  // Changed from Project
                fileStructure.Projects[folder][newName] = content;  // Changed from Project
                break;
            }
        }
    }
    
    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
    applyFolderStates(states);
}

// Add these helper functions first
function isDescendant(draggedPath, targetPath) {
    return targetPath.startsWith(draggedPath + '/');
}

function getItemPath(element) {
    const pathParts = [];
    let current = element;
    
    while (current && !current.classList.contains('file-tree')) {
        if (current.classList.contains('file-item')) {
            pathParts.unshift(current.querySelector('span:last-child').textContent);
        }
        current = current.parentElement;
    }
    
    return pathParts.join('/');
}

// Add the moveItem function
function moveItem(sourcePath, targetPath, isFolder) {
    const states = getFolderStates();
    
    if (isFolder) {
        // Move folder
        const sourceContent = fileStructure.Projects[sourcePath];  // Changed from Project
        delete fileStructure.Projects[sourcePath];  // Changed from Project
        
        if (!fileStructure.Projects[targetPath]) {  // Changed from Project
            fileStructure.Projects[targetPath] = {};  // Changed from Project
        }
        fileStructure.Projects[targetPath][sourcePath] = sourceContent;  // Changed from Project
    } else {
        // Move file
        let sourceContent;
        // Find and remove file from source
        for (const folder in fileStructure.Projects) {  // Changed from Project
            if (fileStructure.Projects[folder].hasOwnProperty(sourcePath)) {  // Changed from Project
                sourceContent = fileStructure.Projects[folder][sourcePath];  // Changed from Project
                delete fileStructure.Projects[folder][sourcePath];  // Changed from Project
                break;
            }
        }
        
        // Add file to target
        if (targetPath === "Projects") {  // Changed from Project
            fileStructure.Projects[sourcePath] = sourceContent;  // Changed from Project
        } else {
            if (!fileStructure.Projects[targetPath]) {  // Changed from Project
                fileStructure.Projects[targetPath] = {};  // Changed from Project
            }
            fileStructure.Projects[targetPath][sourcePath] = sourceContent;  // Changed from Project
        }
    }
    
    // Re-render and restore states
    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
    applyFolderStates(states);
}

// Initialize Monaco Editor with Firebase content
require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.21.2/min/vs' }});
require(['vs/editor/editor.main'], async function() {
    try {
        // Load projects first
        await loadProjectsFromFirestore();

        // Initialize content variables
        const defaultTexContent = "\\documentclass{article}\n\\begin{document}\n\\end{document}";
        const defaultBibContent = "@article{example,\n  author = {Author},\n  title = {Title},\n  year = {2024}\n}";

        let texContent = defaultTexContent;
        let bibContent = defaultBibContent;

        // Try to load content from current project
        if (currentProject && fileStructure[currentProject]) {
            if (mainTexFile && fileStructure[currentProject][mainTexFile]) {
                texContent = fileStructure[currentProject][mainTexFile];
            }
            
            // Find the first .bib file in the project
            const bibFile = Object.entries(fileStructure[currentProject])
                .find(([key, _]) => key.endsWith('.bib'));
            if (bibFile) {
                bibContent = bibFile[1];
            }
        }

        // Update the file structure with initial content
        if (!fileStructure.Projects) {  // Changed from Project
            fileStructure.Projects = {};  // Changed from Project
        }
        
        // Register LaTeX language
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

        // Create editors - only once
        texEditor = monaco.editor.create(document.getElementById('tex-editor'), {
            value: texContent,
            language: 'latex',
            theme: 'vs-dark',
            wordWrap: 'on',
            automaticLayout: true
        });

        bibEditor = monaco.editor.create(document.getElementById('bib-editor'), {
            value: bibContent,
            language: 'bibtex',
            theme: 'vs-dark',
            wordWrap: 'on',
            automaticLayout: true
        });

        // Set up event listeners
        texEditor.onDidChangeModelContent(() => {
            if (currentFile.endsWith(".tex")) {
                fileStructure.Projects[currentFile] = texEditor.getValue();  // Changed from Project
            }
            startAutoSaveDebounced();
        });

        bibEditor.onDidChangeModelContent(() => {
            if (currentFile.endsWith(".bib")) {
                fileStructure.Projects[currentFile] = bibEditor.getValue();  // Changed from Project
            }
            startAutoSaveDebounced();
        });

        // Handle container z-index
        const editorContainer = document.getElementById('editor-container');
        const previewContainer = document.getElementById('preview-container');

        editorContainer.addEventListener('mouseenter', () => {
            editorContainer.style.zIndex = '2';
            previewContainer.style.zIndex = '1';
        });

        previewContainer.addEventListener('mouseenter', () => {
            previewContainer.style.zIndex = '2';
            editorContainer.style.zIndex = '1';
        });

        // Initialize file explorer
        const explorerContainer = document.getElementById("file-tree");
        renderFileExplorer(explorerContainer, fileStructure);

        // Set initial focus
        texEditor.focus();

    } catch (error) {
        console.error("Error initializing editors:", error);
    }
});