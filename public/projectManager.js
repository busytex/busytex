import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { renderFileExplorer } from './uiManager.js';

// Module-level variables
export let projectStructure = []; // Array of project names
export let explorerTree = { Projects: {} };  // UI representation
export let currentProject = null;
export let mainTexFile = "main.tex";
let fileStructure = {};  // Make this private to the module - internal project files

export async function createProjectInFirestore(projectName) {
    // Validate project name
    if (!projectName?.trim() || projectStructure.includes(projectName)) {
        throw new Error('Invalid or duplicate project name');
    }

    const projectRef = doc(db, "projects", projectName);
    
    const projectData = {
        name: projectName,
        createdAt: new Date().toISOString(),
        fileStructure: {
            [mainTexFile]: "\\documentclass{article}\n\\begin{document}\n\\end{document}"
        },
        mainTexFile,
        uiState: {
            expandedFolders: ['Projects']
        }
    };

    await setDoc(projectRef, projectData);
    
    // Update local structures
    projectStructure.push(projectName);
    explorerTree.Projects[projectName] = {};

    return projectData;
}

export async function loadProjectsFromFirestore() {
    try {
        const projectsRef = collection(db, "projects");
        let uiState = {}; // Default UI state

        // Load UI state and settings from global collection
        const [uiStateDoc, settingsDoc] = await Promise.all([
            getDoc(doc(db, "global", "uiState")),
            getDoc(doc(db, "global", "settings"))
        ]);

        // Get saved UI state or create default
        if (uiStateDoc.exists()) {
            uiState = uiStateDoc.data();
            currentProject = uiState.currentProject || null;
        } else {
            // Create default UI state if it doesn't exist
            await setDoc(doc(db, "global", "uiState"), {
                currentProject: null,
                expandedFolders: ['Projects'],
                lastModified: new Date().toISOString()
            });
        }

        // Reset data structures
        projectStructure = [];
        explorerTree = { Projects: {} };
        fileStructure = {};

        // Load all projects
        const querySnapshot = await getDocs(projectsRef);
        querySnapshot.forEach((doc) => {
            const project = doc.data();

            // Set default project if none is current
            if (!currentProject) {
                mainTexFile = project.mainTexFile || "main.tex";
                currentProject = project.name;
            }

            // Store project name
            projectStructure.push(project.name);
            
            // Store file structure internally
            fileStructure[project.name] = project.fileStructure || {};

            // Build explorer tree from file structure
            explorerTree.Projects[project.name] = {};  // Create project folder
            
            // Add files under project folder
            if (project.fileStructure) {
                Object.entries(project.fileStructure).forEach(([fileName, content]) => {
                    explorerTree.Projects[project.name][fileName] = content;
                });
            }
        });

        // If we have saved explorer tree state in settings, restore it
        if (settingsDoc.exists()) {
            const settings = settingsDoc.data();
            if (settings.explorerTree?.Projects) {
                // Merge saved structure with loaded files
                Object.entries(settings.explorerTree.Projects).forEach(([projectName, structure]) => {
                    if (explorerTree.Projects[projectName]) {
                        explorerTree.Projects[projectName] = {
                            ...structure,
                            ...explorerTree.Projects[projectName]
                        };
                    }
                });
            }
        }

        console.log("Loaded projects:", projectStructure);
        console.log("File structure:", fileStructure);
        console.log("Explorer tree:", explorerTree);
        console.log("UI state:", uiState);

        return uiState;
    } catch (error) {
        console.error("Error loading projects:", error);
        throw error;
    }
}

// Save both file structure and UI state
export async function persistCurrentProjectToFirestore(uiState = {}) {
    try {
        // Save project data without UI state
        if (currentProject) {
            const projectRef = doc(db, "projects", currentProject);
            await setDoc(projectRef, {
                name: currentProject,
                fileStructure: fileStructure[currentProject],
                lastModified: new Date().toISOString(),
                mainTexFile: mainTexFile
            }, { merge: true });
        }

        // Save UI state separately in global collection
        const uiStateRef = doc(db, "global", "uiState");
        await setDoc(uiStateRef, {
            currentProject,
            expandedFolders: uiState.expandedFolders || [],
            lastModified: new Date().toISOString()
        }, { merge: true });

        // Save other global settings
        const globalRef = doc(db, "global", "settings");
        await setDoc(globalRef, {
            projectStructure: projectStructure,
            explorerTree: { Projects: Object.fromEntries(
                projectStructure.map(name => [name, {}])
            )},
            lastModified: new Date().toISOString()
        }, { merge: true });

    } catch (error) {
        console.error("Error saving structure:", error);
    }
}

// Add getter for file structure
export function getCurrentProjectFiles() {
    return currentProject ? fileStructure[currentProject] : null;
}

export async function switchProject(projectName) {
    if (!projectStructure.includes(projectName)) {
        console.error(`Project ${projectName} not found`);
        return;
    }

    currentProject = projectName;
    const projectRef = doc(db, "projects", projectName);
    const projectDoc = await getDoc(projectRef);
    
    if (projectDoc.exists()) {
        mainTexFile = projectDoc.data().mainTexFile || "main.tex";
    }

    // Update UI state in Firestore
    await setDoc(doc(db, "global", "uiState"), {
        currentProject: projectName,
        lastModified: new Date().toISOString()
    }, { merge: true });

    return getCurrentProjectFiles();
}