import { 
    explorerTree, 
    persistCurrentProjectToFirestore, 
    getCurrentProjectFiles,
    projectStructure,
    currentProject,
    mainTexFile,
    createProjectInFirestore
} from './projectManager.js';
import { doc, setDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { getEditors } from './editorManager.js';  // Add this import

// Add to top-level after imports
function setupContextMenuHandlers() {
    // Handle context menu cleanup
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

    // Handle explorer mouse leave
    document.querySelector('.file-explorer').addEventListener('mouseleave', (e) => {
        if (!document.querySelector('.context-menu')) {
            e.currentTarget.classList.remove('context-active');
        }
    });
}

// Keep only this one definition of getFolderStates at the top level
export function getFolderStates() {
    const states = {};  // Changed from new Map()
    const folders = document.querySelectorAll('.folder');
    
    folders.forEach(folder => {
        const folderName = folder.querySelector('.file-item span:last-child').textContent;
        const isExpanded = folder.querySelector('ul').style.display === 'block';
        states[folderName] = isExpanded;  // Changed from states.set()
    });
    
    return states;
}

// Add these functions before renderFileExplorer

// Update applyFolderStates to work with plain object
function applyFolderStates(states) {
    const folders = document.querySelectorAll('.folder');
    
    folders.forEach(folder => {
        const folderName = folder.querySelector('.file-item span:last-child').textContent;
        const shouldBeExpanded = states[folderName];  // Changed from states.get()
        
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
async function renameFileOrFolder(oldPath, newName, isFolder) {
    const states = getFolderStates();
    const currentFiles = getCurrentProjectFiles();
    
    if (isFolder) {
        // Rename folder in explorer tree
        const folderContent = explorerTree.Projects[oldPath];
        delete explorerTree.Projects[oldPath];
        explorerTree.Projects[newName] = folderContent;
    } else {
        // Rename file in current project
        if (currentFiles) {
            const content = currentFiles[oldPath];
            delete currentFiles[oldPath];
            currentFiles[newName] = content;
        }
    }
    
    await updateUIAfterChange(states);
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
async function moveItem(sourcePath, targetPath, isFolder) {
    const states = getFolderStates();
    const currentFiles = getCurrentProjectFiles();
    
    if (isFolder) {
        // Move folder in explorer tree
        const sourceContent = explorerTree.Projects[sourcePath];
        if (sourceContent) {
            delete explorerTree.Projects[sourcePath];
            
            if (!explorerTree.Projects[targetPath]) {
                explorerTree.Projects[targetPath] = {};
            }
            explorerTree.Projects[targetPath][sourcePath] = sourceContent;
        }
    } else {
        // Move file within current project
        if (currentFiles) {
            // Get source file content from current location
            let sourceContent;
            if (explorerTree.Projects[sourcePath]) {
                sourceContent = explorerTree.Projects[sourcePath];
                delete explorerTree.Projects[sourcePath];
            } else {
                // Look for file in subfolders
                for (const folder in explorerTree.Projects) {
                    if (explorerTree.Projects[folder] && 
                        explorerTree.Projects[folder][sourcePath]) {
                        sourceContent = explorerTree.Projects[folder][sourcePath];
                        delete explorerTree.Projects[folder][sourcePath];
                        break;
                    }
                }
            }

            if (sourceContent) {
                // Move to new location
                if (targetPath === "Projects") {
                    explorerTree.Projects[sourcePath] = sourceContent;
                } else {
                    if (!explorerTree.Projects[targetPath]) {
                        explorerTree.Projects[targetPath] = {};
                    }
                    explorerTree.Projects[targetPath][sourcePath] = sourceContent;
                }

                // Update current project's file structure
                currentFiles[sourcePath] = sourceContent;
            }
        }
    }
    
    // Save changes and update UI
    await updateUIAfterChange(states);
}

// Add the moveFile function
function moveFile(sourcePath, targetPath, currentFiles) {
    // Parse paths
    const sourcePathParts = sourcePath.split('/').filter(Boolean);
    const fileName = sourcePathParts.pop();
    const sourceFolder = sourcePathParts.join('/');
    
    // Get content and remove from source
    let fileContent = null;
    
    if (sourceFolder) {
        if (explorerTree.Projects[sourceFolder]?.[fileName]) {
            fileContent = explorerTree.Projects[sourceFolder][fileName];
            delete explorerTree.Projects[sourceFolder][fileName];
            
            // Clean up empty folders
            if (Object.keys(explorerTree.Projects[sourceFolder]).length === 0) {
                delete explorerTree.Projects[sourceFolder];
            }
        }
    } else {
        if (explorerTree.Projects[fileName]) {
            fileContent = explorerTree.Projects[fileName];
            delete explorerTree.Projects[fileName];
        }
    }

    // Add to target
    explorerTree.Projects[targetPath] = explorerTree.Projects[targetPath] || {};
    explorerTree.Projects[targetPath][fileName] = fileContent;
}

// Modify the renderFileExplorer function to handle UI state
export function renderFileExplorer(container, structure, savedState = {}) {
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
                
                const targetPath = getItemPath(itemContent);
                if (targetPath === 'Projects') {
                    e.dataTransfer.dropEffect = 'none'; // Show 'not-allowed' cursor
                    return; // Don't add drag-over class for Projects root
                }
                
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
                
                // Prevent dropping into descendant or directly under Projects
                if ((data.isFolder && isDescendant(data.path, targetPath)) || 
                    targetPath === 'Projects') {
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
            
            // When creating folder items, check saved state
            const folderPath = getItemPath(itemContent);
            if (savedState[folderPath]) {
                subUl.style.display = "block";
                itemContent.classList.add("expanded");
                chevron.style.transform = "rotate(90deg)";
            }

            addFolderClickHandler(itemContent, subUl, chevron);
            
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
                if (key === mainTexFile && key in (getCurrentProjectFiles() || {})) {
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
            itemContent.addEventListener("click", () => {
                const folderPath = getItemPath(itemContent.parentElement.parentElement);
                const folder = folderPath === 'Projects' ? null : folderPath;
                handleFileClick(key, folder);
            });
            
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
            explorerTree.Projects[newProjectName] = explorerTree.Projects[newProjectName] || {};            

            // Make sure the Projects folder is expanded
            states['Projects'] = true;
            
            renderFileExplorer(document.getElementById('file-tree'), explorerTree);
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

    // Skip context menu for Projects root
    const folderName = targetElement.querySelector('span:last-child').textContent;
    if (folderName === 'Projects') return;

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
                handleCreateFolder(folderPath, newFolderName);
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
                    
                    // Ensure the target folder is expanded in the states
                    states[folderPath] = true;
                    
                    // Update the file structure at the correct path
                    if (folderPath === "Projects") {  // Changed from Project
                        explorerTree.Projects[file.name] = "// Empty file content";  // Changed from Project
                    } else if (explorerTree.Projects[folderPath]) {  // Changed from Project
                        explorerTree.Projects[folderPath][file.name] = "// Empty file content";
                    }
                    
                    // Ensure the target folder is expanded in the states
                    states[folderPath] = true;
                    
                    // Re-render and restore states with the target folder expanded
                    renderFileExplorer(document.getElementById('file-tree'), explorerTree);
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
            const folderContent = explorerTree[folderPath];
            if (Object.keys(folderContent).length === 0) {
                const states = getFolderStates();
                delete explorerTree[folderPath];
                // If root folder was deleted, create a new empty root
                if (folderPath === "Projects") {  // Changed from Project
                    explorerTree["New Project"] = {};
                }
                renderFileExplorer(document.getElementById('file-tree'), explorerTree);
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
                renameFileOrFolder(folderPath, newName, true);
            }
            explorer.classList.remove('context-active');
            menu.remove();
        };
        menu.appendChild(renameItem);
    } else {
        // File context menu
        const fileName = targetElement.querySelector('span:last-child').textContent;
        const currentFiles = getCurrentProjectFiles();
        const isRootTexFile = fileName.endsWith('.tex') && 
                             fileName in (currentFiles || {});
        
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
                    renderFileExplorer(document.getElementById('file-tree'), explorerTree);
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
            handleDeleteFile(fileName);
            explorer.classList.remove('context-active');
            menu.remove();
        };

        menu.appendChild(deleteItem);
    }

    menu.style.left = `${e.pageX}px`;
    menu.style.top = `${e.pageY}px`;
    document.body.appendChild(menu);
}

// In the file upload handler
function handleFileUpload(e) {
    const file = e.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = async function(e) {
            const content = e.target.result;
            const states = getFolderStates();  // This now returns a plain object
            
            // Update this line to use object property assignment instead of Map.set
            states['Projects'] = true;  // Changed from states.set('Projects', true)
            
            // Continue with existing code...
            await loadFile(file.name, content);
            renderFileExplorer(document.getElementById('file-tree'), explorerTree);
            applyFolderStates(states);
            persistCurrentProjectToFirestore();
        };
        reader.readAsText(file);
    }
}

async function saveFolderStates(states) {
    if (!currentProject) return;
    
    const projectRef = doc(db, "projects", currentProject);
    await setDoc(projectRef, {
        uiState: {
            expandedFolders: Object.entries(states)
                .filter(([_, expanded]) => expanded)
                .map(([name]) => name)
        }
    }, { merge: true });
}

// Update folder click handler
function addFolderClickHandler(content, subUl, chevron) {
    content.addEventListener("click", async (e) => {
        e.stopPropagation();
        const isExpanded = subUl.style.display !== "none";
        subUl.style.display = isExpanded ? "none" : "block";
        content.classList.toggle("expanded");
        chevron.style.transform = isExpanded ? "rotate(0)" : "rotate(90deg)";
        
        const states = getFolderStates();
        await saveFolderStates(states);
    });
}

// Add this function to handle file loading
async function handleFileClick(fileName, folder = null) {
    const currentFiles = getCurrentProjectFiles();
    if (!currentFiles) return;

    let content = null;
    
    // Check if file is in root or in a folder
    if (folder) {
        content = currentFiles[folder]?.[fileName];
    } else {
        content = currentFiles[fileName];
    }

    // If content exists, load it into the editor
    if (content) {
        const { texEditor, bibEditor } = getEditors();  // Get editors from editorManager
        const editor = fileName.endsWith('.tex') ? texEditor : bibEditor;
        if (editor) {
            editor.setValue(content);
            editor.focus();
        } else {
            console.warn(`No editor available for file type: ${fileName}`);
        }
    } else {
        console.warn(`No content found for file: ${fileName}`);
    }
}

// Update updateUIAfterChange to include state saving
async function updateUIAfterChange(states) {
    renderFileExplorer(document.getElementById('file-tree'), explorerTree);
    applyFolderStates(states);
    await Promise.all([
        persistCurrentProjectToFirestore(),
        saveFolderStates(states)
    ]);
}

// Update delete handling in context menu
async function handleDeleteFile(fileName) {
    const states = getFolderStates();
    let fileDeleted = false;

    // Check if file is directly in Projects folder
    if (explorerTree.Projects.hasOwnProperty(fileName)) {  // Changed from Project
        delete explorerTree.Projects[fileName];  // Changed from Project
        fileDeleted = true;
    } else {
        // Check in subfolders
        for (const folder in explorerTree.Projects) {  // Changed from Project
            if (typeof explorerTree.Projects[folder] === 'object' &&  // Changed from Project
                explorerTree.Projects[folder].hasOwnProperty(fileName)) {  // Changed from Project
                delete explorerTree.Projects[folder][fileName];  // Changed from Project
                fileDeleted = true;
                break;
            }
        }
    }

    if (fileDeleted) {
        await updateUIAfterChange(states);
    }
}

// Update create folder handling
async function handleCreateFolder(folderPath, newFolderName) {
    const states = getFolderStates();
    
    if (folderPath === "Projects") {
        explorerTree.Projects[newFolderName] = {};
    } else if (explorerTree.Projects[folderPath]) {
        explorerTree.Projects[folderPath][newFolderName] = {};
    }
    
    states[folderPath] = true; // Ensure parent folder stays expanded
    await updateUIAfterChange(states);
}

// Add to existing exports
export { setupContextMenuHandlers };
