{{% CONTENT_TYPE:TEXT }}

Submitted by: {{ email }}

## {{ title }}

{{#body}}
{{body}}
{{/body}}

<details><summary>Client Details</summary><p>

| Name  | Value |
| ------------- | ------------- |
{{# each(applicationDetails)}}| {{ @key }} | {{.}} |
{{/}}

</p></details>


{{#additionalData}}
{{additionalData}}
{{/additionalData}}

{{#screenshotURL}}
![Screenshot]({{ screenshotURL }})
{{/screenshotURL}}