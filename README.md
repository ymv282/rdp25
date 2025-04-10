This is the repository for the module "radar design project"

The structure is as follows:

`code/`

code directory, contains all given code and is the directory for the to-be-written code snippets 

---

Files in the code folder:


`AWG_doRun.m`, `AWG_doStop.m`, `AWG_download.m`, `AWG_open.m`, `VISA_Instrument.m`, `download2AWG.m`:
Interface between matlab and iqtools/arbitrary waveform generator, *do not change*

`main.m`:
Main script

`connect2AWG.m`:
Initilizes the data transfer between matlab and AWG

`connect2RTO.m`:
Initializes the data transfer between matlab and RTO

`createWaveform.m`:
This function is going to create the waveform -> Your task

`getWaveform.m`:
Acquires waveform from RTO

`initAWG.m`:
Preset the AWG to predetermined default values -> To define the correct values is your task

`initRTO.m`:
Preset the RTO to predetermined default values -> To define the correct values is your task

`windowData.m`:
Apply window to acquired waveform -> Your task

`plotWaveform.m`:
Processes and plots acquired waveform -> Your task

`saveWaveform.m`:
Save acquired waveform



---

`iqtools/`

framework to control the arbitrary waveform generator Agilent M9505A

will be called by functions in the code directory
*the files in this folder do not need to be changed*

---

`images/`

Folder in which images are stored, which are displayed in .md-files in this gitlab repo

---

`measurements/`

Folder to store measurement results

---

`documentation/`

Store all documentation-related stuff here (text files, powerpoint files, matlab plots, pictures, etc.)

---

**How to get started?**

Clone the directory to the given mwt account.

If you are already familiar with radar signal processing and matlab you can skip the simulation part in the task list and start directly implementing your signal processing and settings in the /code directory.

If you are not familiar with radar signal processing it is highly recommended to first get started by creating a simulation.
All necessary steps are described here -> [Task list](Tasks_2024.md)


