import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { renderFileExplorer } from './uiManager.js';

// Update the initial structure declaration
export let projectStructure = []; // Holds all projects
export let fileStructure = {};  // Holds individual project file mappings
export let currentProject = null;  // Add this to track the current project
export let mainTexFile = "main.tex";

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

        projectStructure = [];  // Reset the array of project names
        fileStructure = {};     // Reset the object mapping projects to file structures

        // Use currentProjectSnap instead of currentProjectRef
        currentProject = currentProjectSnap.exists() ? currentProjectSnap.data().name : "";

        querySnapshot.forEach((doc) => {
            const project = doc.data();

            mainTexFile = project.mainTexFile || "main.tex";
            fileStructure = project.fileStructure || {};

            // Store project names in projectStructure
            projectStructure.push(project.name);
            
            // Merge each project's UI state into the global uiState object
            if (project.uiState) {
                uiState = { ...uiState, ...project.uiState };
            }
        });
       
        console.log("Loaded projects:", projectStructure);
        console.log("File structure:", fileStructure);

        return uiState;
 
    } catch (error) {
        console.error("Error loading projects:", error);
        alert("Failed to load projects from Firestore");
    }
}

// Save both file structure and UI state
export async function persistCurrentProjectToFirestore(uiState = {}) {
    try {
        // Save project-specific structure and state
        if (currentProject) {
            const projectRef = doc(db, "projects", currentProject);
            await setDoc(projectRef, {
                fileStructure: fileStructure.Projects[currentProject],
                uiState: uiState,
                lastModified: new Date().toISOString()
            }, { merge: true });
        }

        // Save global settings
        const globalRef = doc(db, "global", "settings");
        
        // Check if document exists, if not create it
        const globalDoc = await getDoc(globalRef);
        if (!globalDoc.exists()) {
            // Create the document if it doesn't exist
            await setDoc(globalRef, {
                projectStructure: fileStructure,
                lastModified: new Date().toISOString()
            });
        } else {
            // Update existing document
            await setDoc(globalRef, {
                projectStructure: fileStructure,
                lastModified: new Date().toISOString()
            }, { merge: true });
        }

    } catch (error) {
        console.error("Error saving structure:", error);
    }
}