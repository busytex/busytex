import { fileStructure, currentProject, saveFileStructure, persistCurrentProjectToFirestore } from './projectManager.js';
import { getEditors } from './editorManager.js';

const { texEditor, bibEditor } = getEditors();
import { renderFileExplorer } from './uiManager.js';

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

async function renameFileOrFolder(oldPath, newName, isFolder) {
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

    // Save both structure and state
    await saveFileStructure(states);

    renderFileExplorer(document.getElementById('file-tree'), fileStructure, states);
    applyFolderStates(states);
}

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

async function moveItem(sourcePath, targetPath, isFolder) {
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

    // Save both structure and state
    await saveFileStructure(states);
    await persistCurrentProjectToFirestore(states);

    // Re-render and restore states
    renderFileExplorer(document.getElementById('file-tree'), fileStructure);
    applyFolderStates(states);
}

async function createNewFile(filename, content = '') {
    fileStructure.Projects[currentProject][filename] = content;
    await saveFileStructure();
}

async function deleteFile(filename) {
    delete fileStructure.Projects[currentProject][filename];
    await saveFileStructure();
}

async function moveFile(filename, targetFolder) {
    const content = fileStructure.Projects[currentProject][filename];
    const newPath = `${targetFolder}/${filename}`;
    fileStructure.Projects[currentProject][newPath] = content;
    delete fileStructure.Projects[currentProject][filename];
    await saveFileStructure();
}