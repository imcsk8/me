+++
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
date = {{ .Date }}
draft = true
description = "{{ replace .File.ContentBaseName "-" " " | title }}"
summary = "{{ replace .File.ContentBaseName "-" " " | title }}"
+++
