import { fileStructure } from './projectManager.js';

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

export function renderFileExplorer(container, structure) {
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
