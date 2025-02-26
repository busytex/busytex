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

export async function loadProjectsFromFirestore() {
    try {
        const projectsRef = collection(db, "projects");
        let uiState = {}; // Default UI state

        try {
            const uiStateRef = doc(db, "global", "uiState");
            const uiStateDoc = await getDoc(uiStateRef);
            
            if (!uiStateDoc.exists()) {
                // Create default UI state if it doesn't exist
                await setDoc(uiStateRef, {
                    currentProject: null,
                    lastModified: new Date().toISOString()
                });
            } else {
                uiState = uiStateDoc.data();
            }
        } catch (dbError) {
            console.warn("Could not access UI state:", dbError);
            // Continue with default UI state
        }

        const querySnapshot = await getDocs(projectsRef);
        const currentProjectRef = doc(db, "global", "currentProject");
        const currentProjectSnap = await getDoc(currentProjectRef);  // Get the snapshot

        projectStructure = [];
        explorerTree = { Projects: {} };
        fileStructure = {};

        currentProject = currentProjectSnap.exists() ? currentProjectSnap.data().name : "";

        querySnapshot.forEach((doc) => {
            const project = doc.data();

            if (!currentProject) {
                mainTexFile = project.mainTexFile || "main.tex";
                currentProject = project.name;
            }

            projectStructure.push(project.name);
            
            // Only store file structure internally
            fileStructure[project.name] = project.fileStructure || {};
            
            // Explorer tree only shows project names initially
            explorerTree.Projects[project.name] = {};

            if (project.uiState) {
                uiState = { ...uiState, ...project.uiState };
            }
        });

        console.log("Loaded projects:", projectStructure);
        console.log("Explorer tree:", explorerTree);

        return uiState;
 
    } catch (error) {
        console.error("Error loading projects:", error);
        alert("Failed to load projects from Firestore");
    }
}

// Save both file structure and UI state
export async function persistCurrentProjectToFirestore(uiState = {}) {
    try {
        if (currentProject) {
            const projectRef = doc(db, "projects", currentProject);
            await setDoc(projectRef, {
                name: currentProject,
                fileStructure: fileStructure[currentProject],
                uiState: uiState,
                lastModified: new Date().toISOString(),
                mainTexFile: mainTexFile
            }, { merge: true });
        }

        // Save global settings with only project names
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