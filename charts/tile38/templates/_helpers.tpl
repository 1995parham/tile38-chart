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
Common labels (no component). Callers should add `app.kubernetes.io/component` themselves.
*/}}
{{- define "tile38.labels" -}}
helm.sh/chart: {{ include "tile38.chart" . }}
{{ include "tile38.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ include "tile38.name" . }}
{{- end }}

{{/*
Selector labels — the stable subset that must NOT change across upgrades.
*/}}
{{- define "tile38.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tile38.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-scoped labels. Usage: `include "tile38.componentLabels" (dict "ctx" . "component" "leader")`.
*/}}
{{- define "tile38.componentLabels" -}}
{{ include "tile38.labels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component-scoped selector labels.
*/}}
{{- define "tile38.componentSelectorLabels" -}}
{{ include "tile38.selectorLabels" .ctx }}
app.kubernetes.io/component: {{ .component }}
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
Resolve a value, falling back to the corresponding `global.*` key when the
component value is empty. Usage:
  include "tile38.coalesce" (dict "component" .Values.leader "global" .Values.global "key" "nodeSelector")
*/}}
{{- define "tile38.coalesce" -}}
{{- $componentVal := index .component .key -}}
{{- $globalVal := index .global .key -}}
{{- if $componentVal -}}
{{- toYaml $componentVal -}}
{{- else if $globalVal -}}
{{- toYaml $globalVal -}}
{{- end -}}
{{- end -}}

{{/*
Define url of follow_host for follower
*/}}
{{- define "tile38.follower.followHost" -}}
{{- default (printf "%s-leader" (include "tile38.fullname" .)) .Values.followers.config.configs.follow_host  }}
{{- end }}


{{/*
Define url of follow_port for follower
*/}}
{{- define "tile38.follower.followPort" -}}
{{- default .Values.leader.service.tilePort .Values.followers.config.configs.follow_port }}
{{- end }}


{{- define "tile38.follower.configJson" }}
  {{- $followHost := (printf "%s" (include "tile38.follower.followHost" .) ) }}
  {{- $followPort :=  (include "tile38.follower.followPort" . | int) }}
  {{- $config := dict "follow_host" $followHost "follow_port" $followPort }}
  {{- range $key, $value := .Values.followers.config.configs }}
    {{- if and (ne $key "follow_host") (ne $key "follow_port") }}
      {{- if eq $key "leaderauth" }}
        {{- if $.Values.followers.config.existingSecret }}
          {{/* leaderauth comes from Secret via the init container, not the ConfigMap */}}
        {{- else if eq (toString $value) "" }}
          {{/* no auth configured */}}
        {{- else }}
          {{- $_ := set $config $key $value }}
        {{- end }}
      {{- else }}
        {{- $_ := set $config $key $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- $config | toJson | print }}
{{- end }}

{{/*
Whether the follower headless service should be rendered.
*/}}
{{- define "tile38.followers.headlessEnabled" -}}
{{- if or .Values.followers.persistence.enabled .Values.followers.service.headless -}}
true
{{- end -}}
{{- end -}}
