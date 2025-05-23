# Składnia Helm - Wyjaśnienie

## Podstawowe konstrukcje

### 1. Warunki (if/else)
```yaml
{{- if .Values.autoscaling.enabled }}
  # kod wykonywany gdy autoscaling jest włączony
{{- else }}
  # kod wykonywany gdy autoscaling jest wyłączony
{{- end }}
```
- `{{-` - usuwa białe znaki przed wyrażeniem
- `-}}` - usuwa białe znaki po wyrażeniu
- `.Values` - dostęp do wartości z pliku values.yaml
- `.Values.autoscaling.enabled` - sprawdza wartość klucza enabled w sekcji autoscaling

### 2. Pętle (range)
```yaml
{{- range .Values.ingress.hosts }}
  host: {{ .host }}
  paths:
    {{- range .paths }}
      path: {{ .path }}
    {{- end }}
{{- end }}
```
- `range` - iteruje po elementach listy
- `.` - odnosi się do aktualnego elementu w pętli

### 3. Funkcje pomocnicze (define)
```yaml
{{- define "example-app.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
```
- `define` - definiuje funkcję pomocniczą
- `default` - zwraca wartość domyślną jeśli pierwsza wartość jest pusta
- `trunc` - obcina string do określonej długości
- `trimSuffix` - usuwa określony sufiks

### 4. Włączanie szablonów (include)
```yaml
name: {{ include "example-app.fullname" . }}
```
- `include` - włącza zdefiniowaną wcześniej funkcję pomocniczą
- `.` - przekazuje aktualny kontekst do funkcji

### 5. Warunkowe włączanie sekcji (with)
```yaml
{{- with .Values.podAnnotations }}
annotations:
  {{- toYaml . | nindent 8 }}
{{- end }}
```
- `with` - tworzy nowy kontekst dla zagnieżdżonego kodu
- `toYaml` - konwertuje obiekt na format YAML
- `nindent` - dodaje wcięcia do każdej linii

### 6. Operatory potoku (|)
```yaml
{{ .Values.name | default "default-name" | quote }}
```
- `|` - przekazuje wynik jednej funkcji do drugiej
- `quote` - dodaje cudzysłowy do stringa

### 7. Zmienne
```yaml
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name }}
```
- `:=` - deklaracja zmiennej
- `$name` - zmienna lokalna
- `printf` - formatuje string

### 8. Kontekst (.)
```yaml
{{- define "example-app.labels" -}}
helm.sh/chart: {{ include "example-app.chart" . }}
{{- end }}
```
- `.` - reprezentuje aktualny kontekst
- `.Chart` - dostęp do metadanych chartu
- `.Release` - dostęp do informacji o release
- `.Values` - dostęp do wartości z values.yaml

### 9. Komentarze
```yaml
{{/* To jest komentarz w Helm */}}
```
- `{{/* */}}` - komentarz w szablonie Helm

### 10. Warunkowe renderowanie
```yaml
{{- if and .Values.prometheus.enabled .Values.prometheus.serviceMonitor.enabled }}
  # kod wykonywany gdy oba warunki są spełnione
{{- end }}
```
- `and` - operator logiczny AND
- `or` - operator logiczny OR
- `not` - operator logiczny NOT

## Przydatne funkcje

### 1. String
- `trim` - usuwa białe znaki
- `lower` - konwertuje na małe litery
- `upper` - konwertuje na wielkie litery
- `title` - konwertuje na format tytułu
- `trimPrefix` - usuwa prefiks
- `trimSuffix` - usuwa sufiks

### 2. Listy
- `first` - pierwszy element listy
- `last` - ostatni element listy
- `len` - długość listy
- `sortAlpha` - sortuje alfabetycznie

### 3. Konwersje
- `toYaml` - konwertuje na YAML
- `toJson` - konwertuje na JSON
- `toToml` - konwertuje na TOML

### 4. Formatowanie
- `indent` - dodaje wcięcia
- `nindent` - dodaje wcięcia i nową linię
- `quote` - dodaje cudzysłowy
- `squote` - dodaje pojedyncze cudzysłowy

## Przykłady użycia

### 1. Warunkowe renderowanie zasobów
```yaml
{{- if .Values.resources }}
resources:
  {{- toYaml .Values.resources | nindent 12 }}
{{- end }}
```

### 2. Iteracja po mapie
```yaml
{{- range $key, $value := .Values.annotations }}
{{ $key }}: {{ $value }}
{{- end }}
```

### 3. Łączenie stringów
```yaml
{{- printf "%s-%s" .Release.Name .Chart.Name }}
```

### 4. Warunkowe włączanie sekcji
```yaml
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 8 }}
{{- end }} 