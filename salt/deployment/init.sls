{%- set directory = salt['pillar.get']('application:deploy:directory', '/srv/application') %}
{%- set user = salt['pillar.get']('application:deploy:user') %}
{%- set group = salt['pillar.get']('application:deploy:group') %}
{%- set service = salt['pillar.get']('application:deploy:service') %}
{%- set repository = salt['pillar.get']('application:deploy:repository') %}
{%- set branch = salt['pillar.get']('application:deploy:branch') %}
{%- set runtime = salt['pillar.get']('application:deploy:runtime') %}

git package is installed:
  pkg.installed:
    - name: git

application user is present:
  user.present:
    - name: {{ user }}
    - home: {{ directory }}
    - system: True

application group is present:
  group.present:
    - name: {{ group }}
    - system: True

application directory is present:
  file.directory:
    - name: {{ directory }}
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - user: {{ user }}
      - group: {{ group }}

virtualenv is installed:
  pkg.installed:
    - pkgs:
      - virtualenv
      - {{ runtime }}-virtualenv

deploy app code:
  git.latest:
    - name: {{ repository }}
#    - target: {{ directory }}/code
    - target: {{ directory }}/hello_app
    - user: {{ user }}
    - branch: {{ branch }}
    - require:
      - user: {{ user }}
      - pkg: git

deploy app runtime:
  virtualenv.managed:
    - name: {{ directory }}/runtime
    - user: {{ user }}
    - python: {{ runtime }}
    - system_site_packages: False
    - requirements: {{ directory }}/hello_app/requirements.txt
    - require:
      - git: deploy app code
      - pkg: virtualenv is installed

deploy app systemd unit:
  file.managed:
    - name: /etc/systemd/system/{{ service }}.service
    - context:
        service: {{ service }}
        directory: {{ directory }}
        user: {{ user }}
        group: {{ group }} 
    - source: salt://deployment/files/application.service.j2
    - template: jinja
    - require:
      - virtualenv: deploy app runtime
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/{{ service }}.service

enable application service:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
      - file: deploy app systemd unit

deploy environment file:
  file.managed:
    - name: {{ directory }}/.env
    - user: {{ user }}
    - group: {{ group }}
    - chmod: 0400
    - contents: |
        # Salt managed configuration
        {%- for entry, value in salt['pillar.get']('application:config', '{}').items() %}
        APP_{{ entry | upper }}={{ value }}
        {%- endfor %}
