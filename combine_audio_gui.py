# Python script for GUI front-end to combine audio devices using PulseAudio
# This script provides a simple Tkinter interface to create/delete combined
# sink and source devices. It mimics the behaviour of the bash script using
# dialog but with graphical widgets.

import subprocess
import tkinter as tk
from tkinter import messagebox, simpledialog, ttk


def run_cmd(cmd):
    """Run a shell command and return (stdout, stderr, returncode)."""
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
    stdout, stderr = process.communicate()
    return stdout.strip(), stderr.strip(), process.returncode


def check_pulseaudio():
    """Ensure PulseAudio is running."""
    _, _, code = run_cmd("pactl info")
    if code != 0:
        messagebox.showerror("Combine Audio", "PulseAudio n'est pas actif. Veuillez le demarrer avant de continuer.")
        return False
    return True


def get_sinks():
    out, _, _ = run_cmd("pactl list short sinks")
    sinks = []
    for line in out.splitlines():
        parts = line.split()[:2]
        if len(parts) == 2:
            sinks.append(parts)
    return sinks


def get_sources():
    out, _, _ = run_cmd("pactl list short sources")
    sources = []
    for line in out.splitlines():
        parts = line.split()[:2]
        if len(parts) == 2:
            sources.append(parts)
    return sources


def create_combined(is_sink=True):
    if not check_pulseaudio():
        return
    items = get_sinks() if is_sink else get_sources()
    if not items:
        messagebox.showinfo("Combine Audio", "Aucun périphérique disponible")
        return
    window = tk.Toplevel(root)
    window.title("Choisissez les périphériques")
    selections = {}
    for idx, name in items:
        var = tk.BooleanVar()
        chk = tk.Checkbutton(window, text=f"{idx} - {name}", variable=var)
        chk.pack(anchor="w")
        selections[idx] = (name, var)

    def confirm():
        chosen = [name for _idx, (name, var) in selections.items() if var.get()]
        if len(chosen) < 2:
            messagebox.showerror("Combine Audio", "Sélectionnez au moins deux périphériques")
            return
        default = "combined" if is_sink else "combined_mic"
        name = simpledialog.askstring("Combine Audio", "Entrez un nom pour le périphérique combiné", initialvalue=default)
        if not name:
            name = default
        cmd = (
            f"pactl load-module {'module-combine-sink' if is_sink else 'module-combine-source'} "
            f"{'sink_name' if is_sink else 'source_name'}={name} slaves={','.join(chosen)}"
        )
        _, err, rc = run_cmd(cmd)
        if rc != 0:
            messagebox.showerror("Combine Audio", f"Erreur lors de la création: {err}")
        else:
            messagebox.showinfo("Combine Audio", f"Périphérique '{name}' créé")
        window.destroy()

    btn = tk.Button(window, text="Créer", command=confirm)
    btn.pack(pady=5)


def list_modules(keyword):
    out, _, _ = run_cmd("pactl list short modules")
    modules = []
    for line in out.splitlines():
        parts = line.split()[:2]
        if len(parts) >= 2 and keyword in line:
            modules.append(parts)
    return modules


def purge_combined(is_sink=True):
    keyword = "module-combine-sink" if is_sink else "module-combine-source"
    mods = list_modules(keyword)
    if not mods:
        messagebox.showinfo("Combine Audio", "Aucun périphérique combiné trouvé")
        return
    window = tk.Toplevel(root)
    window.title("Supprimer un périphérique")
    var = tk.StringVar()
    for module_id, _ in mods:
        rb = tk.Radiobutton(window, text=module_id, variable=var, value=module_id)
        rb.pack(anchor="w")

    def confirm():
        mid = var.get()
        if not mid:
            messagebox.showerror("Combine Audio", "Sélectionnez un périphérique")
            return
        _, err, rc = run_cmd(f"pactl unload-module {mid}")
        if rc != 0:
            messagebox.showerror("Combine Audio", f"Erreur lors de la suppression: {err}")
        else:
            messagebox.showinfo("Combine Audio", "Périphérique supprimé")
        window.destroy()

    tk.Button(window, text="Supprimer", command=confirm).pack(pady=5)


root = tk.Tk()
root.title("Combine Audio")

mainframe = ttk.Frame(root, padding=10)
mainframe.pack(fill="both", expand=True)

btn1 = ttk.Button(mainframe, text="Créer un périphérique combiné (Haut-parleurs)", command=lambda: create_combined(True))
btn1.pack(fill="x", pady=2)
btn2 = ttk.Button(mainframe, text="Supprimer un périphérique combiné (Haut-parleurs)", command=lambda: purge_combined(True))
btn2.pack(fill="x", pady=2)
btn3 = ttk.Button(mainframe, text="Créer un micro combiné", command=lambda: create_combined(False))
btn3.pack(fill="x", pady=2)
btn4 = ttk.Button(mainframe, text="Supprimer un micro combiné", command=lambda: purge_combined(False))
btn4.pack(fill="x", pady=2)

quit_btn = ttk.Button(mainframe, text="Quitter", command=root.quit)
quit_btn.pack(fill="x", pady=5)

root.mainloop()
