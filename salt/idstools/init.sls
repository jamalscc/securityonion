# Copyright 2014-2022 Security Onion Solutions, LLC

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
{% from 'allowed_states.map.jinja' import allowed_states %}
{% if sls in allowed_states %}

{% set VERSION = salt['pillar.get']('global:soversion', 'HH1.2.2') %}
{% set IMAGEREPO = salt['pillar.get']('global:imagerepo') %}
{% set MANAGER = salt['grains.get']('master') %}
{% set ENGINE = salt['pillar.get']('global:mdengine', '') %}
{% set proxy = salt['pillar.get']('manager:proxy') %}

include:
  - idstools.sync_files

# IDSTools Setup

idstoolslogdir:
  file.directory:
    - name: /opt/so/log/idstools
    - user: 939
    - group: 939
    - makedirs: True

so-ruleupdatecron:
  cron.present:
    - name: /usr/sbin/so-rule-update > /opt/so/log/idstools/download.log 2>&1
    - user: root
    - minute: '1'
    - hour: '7'

so-idstools:
  docker_container.running:
    - image: {{ MANAGER }}:5000/{{ IMAGEREPO }}/so-idstools:{{ VERSION }}
    - hostname: so-idstools
    - user: socore
    {% if proxy %}
    - environment:
      - http_proxy={{ proxy }}
      - https_proxy={{ proxy }}
      - no_proxy={{ salt['pillar.get']('manager:no_proxy') }}
    {% endif %}
    - binds:
      - /opt/so/conf/idstools/etc:/opt/so/idstools/etc:ro
      - /opt/so/rules/nids:/opt/so/rules/nids:rw
    - watch:
      - file: idstoolsetcsync

append_so-idstools_so-status.conf:
  file.append:
    - name: /opt/so/conf/so-status/so-status.conf
    - text: so-idstools

{% else %}

{{sls}}_state_not_allowed:
  test.fail_without_changes:
    - name: {{sls}}_state_not_allowed

{% endif%}