#!/bin/bash

############################
#####    FUNKTIONEN    #####
############################

# Pruefe ob Dateinamen uebergeben wurden
function dateiNamenVorhanden {
	# Wenn die Anzahl der Dateinamen gleich 0 ist
	if [ ${#dateien[@]} -eq 0 ]; then
		return 1 # false
	fi
	return 0 # true
}

# Prueft ob die uebergebenen Dateinamen existieren
function bereinigeDateiNamen {
	# Durch die Dateiliste iterieren
	for datei in "${!dateien[@]}"; do
		# Pruefe ob Datei gefunden werden konnte
		if [ ! -f "${dateien[$datei]}" ]; then
			# Wenn nicht, Fehlermeldung ausgeben
			echo "$BASH_SOURCE: Die Datei \"${dateien[$datei]}\" existiert nicht."
			# Nicht gefundenen Dateinamen aus Array loeschen
			unset dateien[$datei];
		fi
	done
}

# Prueft ob Dateinamen angegeben wurden und entfernt
# nicht vorhandene Dateinamen aus der Liste
function dateienVorbereiten {
	# Pruefe ob Dateiname/n angegeben wurde/n
	if dateiNamenVorhanden;
	then
		# Nicht existierende Dateinamen entfernen
		bereinigeDateiNamen
	else
		# Fehlermeldung anzeigen und Programm beenden
		ausgabe+="\n$BASH_SOURCE: Es wurde kein Dateiname angegeben."
		# Inhalt ausgeben und Script mit Fehlercode beenden
		ausgebenUndBeenden 1
	fi
}

# Liest die Dateiinhalte aus und speichert diese in das
# Dateiinhalts-Array
function dateiInhaltAuslesen {
	# Durch Dateien iterieren
	for datei in "${dateien[@]}"
	do
		# Dateiinhalt auslesen
		inhalt[$datei]="$(cat $datei)"
	done
}

# Sortiert die Liste/n
function sortiereListe {
	# Durch Dateiinhalt iterieren
	for key in "${!inhalt[@]}"
	do
		# Inhalt sortieren
		inhalt[$key]=$(echo "${inhalt[$key]}" | sort -k1 -k2)
	done
}

# Wandelt die Listen in Spalten um
function erzeugeSpalten {
	# Durch Dateiinhalt iterieren
	for key in "${!inhalt[@]}"
	do
		# Spalten erzeugen
		inhalt[$key]=$(echo "${inhalt[$key]}" | column)
	done
}

# Beendet das Script und gibt einen Return-Code zurueck
function beenden {
	# Return Code festlegen
	if [[ $# -gt 0 ]]
		then returnCode=0
		else returnCode=$1
	fi
	exit $returnCode
}

# Ergebnis auf Bildschirm ausgeben und beenden
function ausgebenUndBeenden {
	echo -e "$ausgabe"
	# Script mit uebergebenen Return-Code beenden
	beenden $1
}

# Einzelne Liste fuer die Ausgabe erzeugen
function erzeugeListe {
	# Header erstellen
	liste="$matrNr $(date +"%F %R")\t\tTelefonliste\t\tSeite 1"
	# Text aus Array erzeugen
	liste+="\n\n$1"
	echo "$liste\n\n"
}

# Speichert die Liste/n in Datei/en ab
function speichernUndBeenden {
	# Matrikelnummer ausgeben
	echo "$matrNr"
	# Durch Dateiinhalt iterieren
	for key in "${!inhalt[@]}"
	do
		if [[ $key -eq 0 ]]
			then key="alle_mitarbeiter"
		fi
		# Spalten erzeugen
		echo -e "$(erzeugeListe "${inhalt[$key]}")" > ${key}_sortiert.txt
		echo "Telefonliste in Datei gespeichert, nicht am Screen ausgegeben"
	done
	# Script beenden 
	beenden $1
}

# Die sortierten Listen zu Text rendern
function erzeugeAusgabe {
	# Durch Dateiinhalt iterieren
	for key in "${!inhalt[@]}"
		do ausgabe+=$(erzeugeListe "${inhalt[$key]}")
	done
}

#############################
####    HAUPT-SCRIPT     ####
#############################

# Matrikelnummer festlegen
matrNr="<Matrikel#: 655068> "
		
# Variable für Ausgabe deklarieren
ausgabe=""

# Pruefen ob kein Parameter uebergeben wurde
if [[ $# -eq 0 ]];
	then
		ausgabe+="$matrNr\nAufruf der $BASH_SOURCE Prozedur erfolgte ohne Parameter!"
		ausgebenUndBeenden 1
	else
		####################################
		####    Parameterauswertung     ####
		####################################
		
		# Zulaessige Parameter auf false setzen
		a=false
		s=false
		d=false

		# Parameter auslesen
		while getopts ":asd" param; do
			case $param in
				a) a=true;; # Telefonliste aller Mitarbeiter
				s) s=true;; # Telefonliste(n) am Bildschirm ausgeben
				d) d=true;; # Telefonliste(n) zweispaltig erzeugen
				?) ausgabe+="$matrNr\n$BASH_SOURCE: Die angegebene Option -$OPTARG ist nicht erlaubt"; ausgebenUndBeenden 1;; # Ungueltige Parameter behandeln
			esac
		done
		
		######################################
		####    Vorbereitung der Daten    ####
		######################################

		# Parameter aus Parameter-String entfernen
		shift $(($OPTIND-1))
		
		# Array deklarieren und Dateinamen hinein laden
		declare -a dateien=($@)
		
		# Uebergebene Dateien ueberpruefen und ggfs.
		# ungueltige Dateinamen entfernen
		dateienVorbereiten
		
		# Array für Dateiinhalte deklarieren
		declare -A inhalt
		
		# Dateiinhalte in das Inhalts-Array laden
		dateiInhaltAuslesen
		
		# Array für sortierte Dateiinhalte deklarieren
		declare -A sortierterInhalt
		
		######################################
		####    Parameterverarbeitung     ####
		######################################
		
		# -a Telefonliste aller Mitarbeiter, die in den
		# angegebenen Dateien eingetragen sind, wird erstellt.
		# Fehlt die Option -a, so wird pro angegebener Datei
		# jeweils eine separate Liste erstellt
		if $a;
			then
				# Alle Dateiinhalte zusammenfuehren
				alleInhalte=$(printf '%s\n' "${inhalt[@]}")
				
				# Dateiinhalte schreiben
				unset inhalt
				declare inhalt=("${alleInhalte}")
		fi
		
		# Sortieren der einzelnen Elemente des Inhalts-Arrays
		sortiereListe
		
		# -d Telefonliste(n) zweispaltig erzeugen		
		if $d;
			then erzeugeSpalten
		fi
		
		# Telefonlisten zu Text rendern
		erzeugeAusgabe
		
		# -s Telefonliste(n) am Bildschirm ausgeben;
		# fehlt die Option -s, so wird (werden) die Liste(n)
		# nur in einer Datei gespeichert
		if $s;
			then ausgebenUndBeenden
			else speichernUndBeenden
		fi
fi
exit 1
