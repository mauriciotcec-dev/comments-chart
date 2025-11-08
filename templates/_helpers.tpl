{{- define "comments-system.fullname" -}}
{{- printf "comments-%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
