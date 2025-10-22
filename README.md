# 🇪🇸 Tiny11_es — Post-Setup en Español 🧩

![License](https://img.shields.io/badge/license-MIT-green)
![Windows](https://img.shields.io/badge/Windows-11-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-Script-lightblue)
![Status](https://img.shields.io/badge/Build-Stable-brightgreen)

---

## 🧠 Descripción

**Tiny11_es** automatiza la configuración y limpieza de **Tiny11 / Windows 11 Lite**  
para dejarlo completamente en **español (España)**, sin bloatware y optimizado  
para desarrollo, navegación y ofimática.

> 💡 Caso práctico: diseñado y probado para **Dell Optiplex 780** (Core2Duo, 8 GB RAM),  
> que no cumple con los requisitos oficiales de Windows 11 (sin TPM ni Secure Boot).

---

## ⚖️ Aviso legal

Este proyecto **no incluye Windows** ni distribuye ISOs modificadas.  
Los scripts son de **post-instalación**, para personalizar una instalación legítima de Windows.  

**Tiny11** es un proyecto comunitario del autor [NTDEV](https://archive.org/details/tiny-11-24-h2).  
No redistribuyas ISOs ni versiones alteradas del sistema.

---

## 🧰 Contenido del repositorio

| Archivo | Descripción |
|----------|--------------|
| `PostSetup_Tiny11_ES_BloatFree.ps1` | Script principal PowerShell: idioma español, desbloat, telemetría mínima, rendimiento. |
| `Run_PostSetup_Tiny11_ES_BloatFree.bat` | Lanzador que ejecuta el script con permisos de administrador y sin bloqueo de política. |
| `README.md` | Este documento de guía. |

---

## 🚀 Instalación paso a paso

### 1️⃣ Descarga Tiny11
Desde la fuente oficial del autor:
> 🔗 [https://archive.org/details/tiny-11-24-h2](https://archive.org/details/tiny-11-24-h2)

---

### 2️⃣ Crea el USB de instalación

Usa [Rufus](https://rufus.ie/):

- Imagen ISO: `tiny11.iso`
- **Esquema de partición:** MBR  
- **Sistema destino:** BIOS (o UEFI-CSM)
- **Opciones a marcar:**
  - ✅ “Eliminar requisitos de TPM/Secure Boot”
  - ✅ “Sin cuenta Microsoft”

Haz clic en **Iniciar** y espera a que Rufus prepare el USB.

---

### 💻 3️⃣ Configuración BIOS en Dell Optiplex 780

> ⚙️ **Guía específica para este modelo**

1. **Inserta el USB** con Tiny11 en el puerto frontal.
2. Enciende el PC y pulsa repetidamente **F2** hasta entrar en la **BIOS Setup**.
3. En la pestaña *Boot Sequence*:
   - Asegúrate de que **Legacy Boot** está habilitado.
   - Coloca **USB Storage Device** como primera opción.
4. Pulsa **F10** para guardar y salir.
5. Durante el arranque, pulsa **F12** y selecciona el USB manualmente si no arranca solo.
6. Aparecerá el instalador de Tiny11.  
   Borra todas las particiones antiguas y deja que Windows cree las suyas automáticamente.

> 💡 Consejo: en los Optiplex antiguos el arranque desde USB solo funciona si está conectado a un **puerto USB 2.0** (no azul).

---

### 4️⃣ Completa la instalación

- Instala Tiny11 como un Windows normal.  
- Elige **no conectar a Internet** y **crear cuenta local**.  
- Cuando llegues al escritorio, **no instales nada todavía**.

---

### 5️⃣ Clona o descarga este repositorio

```bash
git clone https://github.com/PepeluiMoreno/Tiny11_es.git
