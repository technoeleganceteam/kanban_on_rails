$(document).on 'click', '.add_fields', (e) ->
  init_tags()

  init_sortable()

window.init_dragula = (ids, project_id, user_id) ->
  dragula(document.getElementById(id) for id in ids)
    .on 'drop', (el, target, source, sibling) ->
      issue_to_section_connections_attributes = []

      for connection in $(target).children()
        issue_to_section_connections_attributes.push
          id: $(connection).data('issue_to_section_connection-id')
          issue_order: $(connection).index()
          column_id: target.id.split('_')[3]

      issues_attributs = [
        id: el.id.split('_')[1]
        source_column_id: source.id.split('_')[3]
        target_column_id: target.id.split('_')[3]
      ]

      update_issue_tags(issues_attributs, issue_to_section_connections_attributes, user_id, project_id)

update_issue_tags = (issues_attributes, issue_to_section_connections_attributes, user_id, project_id) ->
  $.ajax
    url: Routes.user_project_path(user_id, project_id)
    type: 'PATCH'
    data:
      project:
        issue_to_section_connections_attributes: issue_to_section_connections_attributes
        issues_attributes: issues_attributes

window.init_tags = ->
  $('.column_tags').select2
    placeholder: $('#i18n_select_column_tags').text().replace /^\s+/g, ''
    tags: true

  $('.section_tags').select2
    placeholder: $('#i18n_select_section_tags').text().replace /^\s+/g, ''
    tags: true

  $('.issue_tags').select2
    placeholder: $('#i18n_select_issue_tags').text().replace /^\s+/g, ''
    tags: true

init_sortable = ->
  set_sortable_positions()

  $('.sortable').sortable()

  $('.sortable').sortable().bind 'sortupdate', (e, ui) ->
    set_sortable_positions()

set_sortable_positions = ->
  $('.sections').each ->
    $(@).find('.nested-fields').each (i) ->
      $(@).find('.order').last().find('input').val(i + 1)

  $('.columns').each ->
    $(@).find('.nested-fields').each (i) ->
      $(@).find('.order').last().find('input').val(i + 1)

window.init_infinite_scroll = (ids) ->
  for id in ids
    window.loading = false

    $("##{ id }").scroll (e) ->
      url = $("##{ id }").find('.next_page_infinite_scroll').attr('href')

      if window.loading == false && url && ($(@).scrollTop() + $(@).innerHeight() >= $(@)[0].scrollHeight)
        window.loading = true

        $.getScript(url)
      return

init_functions = ->
  init_tags()

  init_sortable()

$ ->
  init_functions()

$(window).bind 'page:load', ->
  init_functions()
