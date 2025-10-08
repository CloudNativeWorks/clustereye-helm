{{/*
Expand the name of the chart.
*/}}
{{- define "clustereye-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "clustereye-stack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clustereye-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clustereye-stack.labels" -}}
helm.sh/chart: {{ include "clustereye-stack.chart" . }}
{{ include "clustereye-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clustereye-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clustereye-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Database connection configuration
*/}}
{{- define "clustereye-stack.database.config" -}}
{{- if .Values.externalPostgreSQL.enabled }}
{{- printf "%s:%d" .Values.externalPostgreSQL.host (.Values.externalPostgreSQL.port | int) }}
{{- else }}
{{- printf "%s-postgresql:%d" .Release.Name (5432 | int) }}
{{- end }}
{{- end }}

{{/*
InfluxDB connection configuration
*/}}
{{- define "clustereye-stack.influxdb.config" -}}
{{- if .Values.externalInfluxDB.enabled }}
{{- .Values.externalInfluxDB.url }}
{{- else }}
{{- printf "http://%s-influxdb:%d" .Release.Name (8086 | int) }}
{{- end }}
{{- end }}