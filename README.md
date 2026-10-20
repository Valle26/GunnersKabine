# Gunners Kabine

Trainer-App und Kabinen-TV für den EC Gunners Zirl.

- `index.html` – Trainer-App (Handy, Tablet, PC): https://valle26.github.io/GunnersKabine/
- `tv.html` – Fernseher in der Kabine: https://valle26.github.io/GunnersKabine/tv.html
- `supabase-setup.sql` – einmalig im Supabase SQL Editor ausführen
- `icon.png` – App-Symbol

## Zugangsdaten eintragen

In **index.html** und **tv.html** steht jeweils ganz oben im Skript:

```js
const CFG={url:'https://DEIN-PROJEKT.supabase.co',key:'DEIN-ANON-KEY'};
```

Beide Werte wie in der Kasse eintragen (Supabase → Project Settings → API: Project URL und anon public key).

## Rollen

| Rolle | Darf |
|---|---|
| Admin | alles, auch Einstellungen und Freischaltungen |
| Trainer | Trainings, Spiele, Spieler und Übungen bearbeiten |
| Nur ansehen | alles ansehen, nichts ändern |
| TV | nur lesen, für den Fernseher |

## Mini-PC in der Kabine (Windows)

1. Chrome öffnen, `https://valle26.github.io/GunnersKabine/tv.html` aufrufen und mit dem TV-Login anmelden.
2. Chrome schließen.
3. `Win + R` → `shell:startup` → Enter. Im Ordner: Rechtsklick → Neu → Verknüpfung. Als Ziel einfügen:

   ```
   "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk --noerrdialogs --disable-session-crashed-bubble https://valle26.github.io/GunnersKabine/tv.html
   ```

   Name: `Kabinen-TV`. Ab jetzt startet der TV nach jedem Hochfahren automatisch im Vollbild.
4. Einstellungen → System → Bildschirm und Energie: Bildschirm ausschalten und Energiesparmodus auf **Nie**.
5. Falls der PC ein Passwort hat: automatische Anmeldung einrichten, damit er nach einem Stromausfall nicht am Sperrbildschirm hängt.

Den Kiosk-Modus beendest du mit `Alt + F4`.
