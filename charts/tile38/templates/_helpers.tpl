{{/*
Expand the name of the chart.
*/}}
{{- define "tile38.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tile38.fullname" -}}
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
{{- define "tile38.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tile38.labels" -}}
helm.sh/chart: {{ include "tile38.chart" . }}
{{ include "tile38.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tile38.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tile38.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tile38.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tile38.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define url of follow_host for follower
*/}}
{{- define "tile38.follower.followHost" -}}
{{- default (printf "%s-leader" (include "tile38.fullname" .)) .Values.followers.config.follow_host  }}
{{- end }}


{{/*
Define url of follow_port for follower
*/}}
{{- define "tile38.follower.followPort" -}}
{{- default .Values.leader.service.tilePort .Values.followers.config.follow_port }}
{{- end }}


{{- define "tile38.follower.configJson" }}
  {{- $followHost := (printf "%s" (include "tile38.follower.followHost" .) ) }}
  {{- $followPort :=  (include "tile38.follower.followPort" . | int) }}
  {{- $config := dict "follow_host" }}
  {{- range $key, $value := .Values.followers.config.configs }}
    {{- if eq $key "follow_host" }}
      {{- $_ := set $config "follow_host" $followHost }}
    {{- else if eq $key "follow_port"}}
      {{- $_ := set $config "follow_port" $followPort }}
    {{- else }}
      {{- $_ := set $config $key $value }}
    {{- end }}
  {{- end }}
{{- $config | toJson | print }}
{{- end }}


