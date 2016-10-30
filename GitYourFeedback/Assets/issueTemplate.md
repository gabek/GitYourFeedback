{{% CONTENT_TYPE:TEXT }}

Submitted by: {{ email }}

{{ title }}

| Name  | Value |
| ------------- | ------------- |
{{# each(applicationDetails)}}| {{ @key }} | {{.}} |
{{/}}

{{#additionalData}}
{{additionalData}}
{{/additionalData}}

{{#screenshotURL}}
![Screenshot]({{ screenshotURL }})
{{/screenshotURL}}