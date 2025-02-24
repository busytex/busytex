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

export async function loadProjectsFromFirestore() {
    try {
        const projectsRef = collection(db, "projects");
        const querySnapshot = await getDocs(projectsRef);

        // Initialize the structure with Projects object first
        fileStructure = { Projects: {} };

        querySnapshot.forEach((doc) => {
            const project = doc.data();
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

// Add this new function to save file structure
export async function saveFileStructure() {
    try {
        if (!currentProject) {
            console.warn("No project selected, cannot save file structure");
            return;
        }

        const projectRef = doc(db, "projects", currentProject);
        await updateDoc(projectRef, {
            fileStructure: fileStructure.Projects[currentProject],
            lastModified: new Date().toISOString()
        });

        console.log("File structure saved successfully");
    } catch (error) {
        console.error("Error saving file structure:", error);
    }
}