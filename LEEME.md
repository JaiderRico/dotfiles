# Dotfiles — Arch Linux + Hyprland

Configuración personal de Hyprland, Waybar, Kitty, GTK, y herramientas asociadas.

## Requisitos

- Instalación base de Arch Linux (arch-chroot, usuario con sudo, conectividad de red)
- `git` y `stow` (o crea los enlaces manualmente)

## 1. Instalación base de Arch (resumen)

```bash
# Particionar (ej. /dev/sda1 → EFI, /dev/sda2 → root)
cfdisk /dev/sda
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot

# Paquetes esenciales
pacstrap -K /mnt base base-devel linux linux-firmware sudo vim git networkmanager

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Zona horaria, locale, hostname
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_CO.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_CO.UTF-8" > /etc/locale.conf
echo "LANG=es_CO.UTF-8" > /etc/locale.conf
echo "tu-hostname" > /etc/hostname

# Usuario
useradd -m -G wheel,audio,video,storage jaider
passwd jaider
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/wheel

# Red
systemctl enable NetworkManager

# Salir y reiniciar
exit
umount -R /mnt
reboot
```

## 2. Clonar este repositorio

```bash
sudo pacman -S git stow
git clone https://github.com/JaiderRico/dotfiles.git ~/dotfiles
```

## 3. Instalar todos los paquetes

### Paquetes nativos (Arch oficial)

```bash
sudo pacman -S --needed - < ~/dotfiles/pkglist-native.txt
```

### Paquetes AUR

Con `yay` o `paru`:

```bash
yay -S --needed - < ~/dotfiles/pkglist-aur.txt
```

## 4. Desplegar las configuraciones

Con GNU Stow (crea enlaces simbólicos automáticamente):

```bash
cd ~/dotfiles
stow */
```

Esto creará los enlaces de `~/dotfiles/hypr/` → `~/.config/hypr/`, `~/dotfiles/waybar/` → `~/.config/waybar/`, etc.

> **Alternativa manual**: si no usas stow, puedes crear los enlaces uno por uno:
> ```bash
> ln -sf ~/dotfiles/hypr ~/.config/hypr
> ln -sf ~/dotfiles/waybar ~/.config/waybar
> ln -sf ~/dotfiles/kitty ~/.config/kitty
> ln -sf ~/dotfiles/swaync ~/.config/swaync
> ln -sf ~/dotfiles/rofi ~/.config/rofi
> ln -sf ~/dotfiles/gtk-3.0 ~/.config/gtk-3.0
> ln -sf ~/dotfiles/gtk-4.0 ~/.config/gtk-4.0
> ln -sf ~/dotfiles/eww ~/.config/eww
> ln -sf ~/dotfiles/fontconfig ~/.config/fontconfig
> ln -sf ~/dotfiles/.bashrc ~/.bashrc
> cp -r ~/dotfiles/systemd/user ~/.config/systemd/user
> ```

## 5. Configurar temas GTK, iconos, cursores, wallpaper

### Tema GTK (Catppuccin Mocha / Yaru)

Los archivos de configuración ya están en el repo:
- `gtk-3.0/settings.ini` — tema GTK3
- `gtk-4.0/settings.ini` — tema GTK4
- `gtk-3.0/gtk.css` y `gtk-4.0/gtk.css` — ajustes CSS personalizados

Los temas Catppuccin GTK y Yaru se instalan desde AUR (ya incluidos en `pkglist-aur.txt`).

### Iconos

El repo instala `papirus-icon-theme` y `papirus-folders-catppuccin-git`. Para cambiar las carpetas:

```bash
papirus-folders -C catppuccin-mocha
```

### Cursores

`catppuccin-cursors-mocha` se instala desde AUR. Actívalo con:

```bash
gsettings set org.gnome.desktop.interface cursor-theme 'Catppuccin-Mocha-Dark'
```

O en `~/.config/hypr/hyprland.conf`:
```
env = XCURSOR_THEME, Catppuccin-Mocha-Dark
env = XCURSOR_SIZE, 24
```

### Wallpaper

Los fondos están en `~/Imágenes/fondo.jpeg` y `~/Imágenes/fondo.png`. Se cargan con `hyprpaper` (config en `hypr/hyprpaper.conf`).

## 6. Pasos finales

### Habilitar servicios

```bash
sudo systemctl enable NetworkManager    # Red
sudo systemctl enable bluetooth          # Bluetooth
sudo systemctl enable tlp               # Ahorro de batería
sudo systemctl enable ufw               # Cortafuegos
sudo systemctl enable fstrim.timer      # TRIM para SSD
sudo systemctl enable --user pipewire   # Audio
sudo systemctl enable --user wireplumber
```

### Instalar fuentes

Las fuentes Nerd Fonts se instalan con `ttf-jetbrains-mono-nerd` y `ttf-nerd-fonts-symbols` (incluidas en la lista nativa).

### Gestor de sesión (SDDM o ly)

Si usas `ly` (incluido en la lista nativa):
```bash
sudo systemctl enable ly
```

### Initramfs (solo si usas NVIDIA o cambiaste kernel)

```bash
sudo mkinitcpio -P
```

### Configurar Hyprland

Asegúrate de que `~/.bashrc` tenga:
```bash
export XDG_CURRENT_DESKTOP=Hyprland
```

Inicia sesión con `uwsm` (recomendado) o selecciona Hyprland desde ly/SDDM.

## Notas

- **Archivos sensibles**: `.ssh/` y claves privadas **no** están en el repo (añadidos a `.gitignore`).
- **Actualizar dotfiles**: después de modificar configs, ejecuta:
  ```bash
  cd ~/dotfiles && stow */
  ```
  Y haz commit/push para respaldar los cambios.
