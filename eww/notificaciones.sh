#!/bin/bash

# Matar otros demonios para que no bloqueen el bus
killall mako dunst swaync 2>/dev/null

# Escuchar estrictamente los miembros de la interfaz de Notificaciones
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | while read -r line; do
    # Capturar solo las cadenas de texto reales
    if echo "$line" | grep -q "string \""; then
        # Extraer el contenido dentro de las comillas
        TEXTO=$(echo "$line" | cut -d '"' -f 2)
        
        # FILTROS: Ignorar la firma de la interfaz y los IDs con formato de dos puntos (ej. :1.1195)
        if [ "$TEXTO" != "org.freedesktop.Notifications" ] && \
           [ "$TEXTO" != "" ] && \
           [[ ! "$TEXTO" =~ ^:[0-9]+\.[0-9]+$ ]]; then
            
            # Mandar el texto limpio a EWW
            echo "$TEXTO"
        fi
    fi
done