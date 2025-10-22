# 🧩 Tiny11 Post-Setup (Español + Limpieza)

Automatiza la conversión y optimización de una instalación **Tiny11** o **Windows 11 ligero** en equipos sin TPM/Secure Boot (por ejemplo Dell Optiplex 780).

---

## ⚠️ Aviso legal
Este repositorio **no incluye Windows** ni ISOs modificadas.  
Tiny11 es un proyecto independiente (autor: [NTDEV](https://archive.org/details/tiny-11-24-h2)).  
Para cumplir la licencia de Microsoft, descárgalo solo desde esa fuente y **no redistribuyas la ISO**.

Este repo contiene únicamente scripts de post-instalación para personalizar una copia legítima de Windows.

---

## 💡 Requisitos
- Windows 11 o Tiny11 ya instalado.
- Conexión a Internet (si no, ten preparados los `.cab` de idioma en `es-ES-cab/`).
- Ejecutar como **Administrador**.

---

## 🚀 Instalación paso a paso

### 1. Descargar Tiny11 (opcional)
Descarga desde:
👉 [https://archive.org/details/tiny-11-24-h2](https://archive.org/details/tiny-11-24-h2)

### 2. Crear USB de instalación
Usa [Rufus](https://rufus.ie/):
- ISO: `tiny11.iso`
- Esquema: MBR
- Destino: BIOS (o UEFI-CSM)
- Marca opciones:
  - "Eliminar requisitos de TPM/Secure Boot"
  - "Sin cuenta Microsoft"

Instala Tiny11 normalmente.

---

### 3. Descargar este repo
Clona o descarga el ZIP:
```bash
git clone https://github.com/<tuusuario>/tiny11-postsetup.git
