# Automated Hotspot Monitor

A lightweight, automated Windows background utility that monitors internet connectivity and ensures your Windows Mobile Hotspot stays active indefinitely—even after power interruptions, brownouts, or router restarts.

## 📌 Features
* Basically checks continuously if the hotspot is on, and will always turn on the hotspot whenever there is internet connection.

## 📂 File Architecture
For the stealth, windowless background execution to function properly, place both files inside the same folder (e.g., `C:\Scripts\`).

```text
📁 C:\Scripts\
 ├── StartHotspot.bat      <- The main monitoring and execution loop script
 └── SilentLaunch.vbs      <- The script that hides the command prompt window
```

## ⚙️ How to set it up in Task Scheduler

To make this run in the background automatically when you turn on your PC or at 5:00 AM, follow these simple steps:

1. Open **Task Scheduler** and click **Create Task...** on the right side.
2. On the **General** tab:
   * Name it `AutomatedHotspotMonitor`.
   * Click **Change User or Group...**, type `SYSTEM`, and click **Check Names**, then click **OK**. *(This hides the window and skips asking for a password).*
   * Check **Run with highest privileges**.
3. On the **Triggers** tab, click **New...** and add two rules:
   * Change the dropdown to **At startup**.
   * Make another new trigger, select **Daily**, and set it to **5:00 AM**.
4. On the **Actions** tab, click **New...**:
   * **Action:** `Start a program`
   * **Program/script:** `wscript.exe`
   * **Add arguments:** `"C:\Scripts\SilentLaunch.vbs" "C:\Scripts\StartHotspot.bat"`
5. On the **Conditions** tab:
   * Uncheck **Start the task only if the computer is on AC power** *(so it works on battery)*.
6. On the **Settings** tab:
   * Go to the very bottom dropdown and change it to **Do not start a new instance**. This stops multiple versions of the script from stacking up.

7. Hit **OK** and you're good to go!

## 🛑 How to turn it off

Since it runs invisibly in the background, you can't close it with an 'X'. To stop it:

1. Open **Task Scheduler**, click **Task Scheduler Library** on the left.
2. Find `AutomatedHotspotMonitor` in the middle list.
3. Click **End** on the right panel to stop it, or **Disable** to turn it off completely.
