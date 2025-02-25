import { fileStructure, persistCurrentProjectToFirestore } from './projectManager.js';

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

            itemContent.addEventListener("click", async (e) => {
                e.stopPropagation();
                const isExpanded = subUl.style.display !== "none";
                subUl.style.display = isExpanded ? "none" : "block";
                itemContent.classList.toggle("expanded");
                chevron.style.transform = isExpanded ? "rotate(0)" : "rotate(90deg)";
                
                const folderStates = getFolderStates();
                await persistCurrentProjectToFirestore(folderStates);
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
            states['Projects'] = true;
            
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
                    
                    // Ensure the target folder is expanded in the states
                    states[folderPath] = true;
                    
                    // Update the file structure at the correct path
                    if (folderPath === "Projects") {  // Changed from Project
                        fileStructure.Projects[file.name] = "// Empty file content";  // Changed from Project
                    } else if (fileStructure.Projects[folderPath]) {  // Changed from Project
                        fileStructure.Projects[folderPath][file.name] = "// Empty file content";
                    }
                    
                    // Ensure the target folder is expanded in the states
                    states[folderPath] = true;
                    
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
            renderFileExplorer(document.getElementById('file-tree'), fileStructure);
            applyFolderStates(states);
        };
        reader.readAsText(file);
    }
}
