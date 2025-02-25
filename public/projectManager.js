import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { renderFileExplorer } from './uiManager.js';

// Update the initial structure declaration
export let projectStructure = { Projects: {} }; // Holds all projects
export let fileStructure = { Projects: {} };  // Holds individual project file mappings
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

// Modify the existing load function to restore UI state
export async function loadProjectsFromFirestore() {
    try {
        const projectsRef = collection(db, "projects");
        const querySnapshot = await getDocs(projectsRef);
        
        fileStructure = [];  // ✅ Projects is now an array
        let uiState = {};
        
        querySnapshot.forEach((doc) => {
            const project = doc.data();
        
            // ✅ Push each project as an object into the array
            fileStructure.push({
                name: project.name,
                fileStructure: project.fileStructure || {},  // Keep the project's file structure
            });
        
            if (project.uiState) {
                uiState = { ...uiState, ...project.uiState };
            }
        
            if (!currentProject) {
                currentProject = project.name;
                mainTexFile = project.mainTexFile || "main.tex";
            }
        });
        
        return uiState; // Return UI state to restore folder states
    } catch (error) {
        console.error("Error loading projects:", error);
        alert("Failed to load projects from Firestore");
    }
}

// Add this new function to update mainTexFile in Firestore
export async function updateMainTexFileInFirestore(projectName, newMainTexFile) {
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

// Save both file structure and UI state
export async function saveFileStructure(uiState = {}) {
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