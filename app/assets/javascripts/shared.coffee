$(document).on 'click', '.add_fields', (e) ->
  init_tags()

  init_sortable()

window.init_dragula = (ids, board_id, user_id) ->
  dragula(document.getElementById(id) for id in ids,
    removeOnSpill: true
    moves: (el, container, handle) ->
      handle.className.indexOf('handle') > -1
  ).on('drop', (el, target, source, sibling) ->
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

      update_issue_tags(issues_attributs, issue_to_section_connections_attributes, user_id, board_id)
  ).on('remove', (el, container, source) ->
    close_issue($(el).data('project_id'), el.id.split('_')[1])
  )

update_issue_tags = (issues_attributes, issue_to_section_connections_attributes, user_id, board_id) ->
  $.ajax
    url: Routes.user_board_path(user_id, board_id)
    type: 'PATCH'
    data:
      board:
        issue_to_section_connections_attributes: issue_to_section_connections_attributes
        issues_attributes: issues_attributes

close_issue = (project_id, issue_id) ->
  $.ajax
    url: Routes.project_issue_path(project_id, issue_id, { format: 'js' })
    type: 'PATCH'
    data:
      issue:
        state: 'closed'

window.init_tags = ->
  $('.column_tags').select2
    width: '100%'
    placeholder: window.i18n_column_tags
    tags: true

  $('.section_tags').select2
    width: '100%'
    placeholder: window.i18n_section_tags
    tags: true

  $('.issue_tags').select2
    width: '100%'
    placeholder: window.i18n_issue_tags
    tags: true

  $('.emails_for_reports').select2
    width: '100%'
    placeholder: window.i18n_emails_for_reports
    tags: true

  $('.issue_project').select2
    width: '100%'
    tags: true
    ajax:
      url: Routes.user_projects_path(window.current_user_id)
      dataType: 'json'
      delay: 250
      data: (params) ->
        {
          q: params.term
          page: params.page
        }
      processResults: (data, params) ->
        params.page = params.page || 1

        { results: data.results, pagination: { more: (params.page * 25) < data.total_count } }

  $('.user_projects').select2
    tags: true
    width: '100%'
    ajax:
      url: Routes.user_projects_path(window.current_user_id)
      dataType: 'json'
      delay: 250
      data: (params) ->
        {
          q: params.term
          page: params.page
        }
      processResults: (data, params) ->
        params.page = params.page || 1

        { results: data.results, pagination: { more: (params.page * 25) < data.total_count } }

window.init_sortable = ->
  set_sortable_positions()

  $('.sortable').sortable()

  $('.sortable').sortable().bind 'sortupdate', (e, ui) ->
    set_sortable_positions()

set_sortable_positions = ->
  $('.sections').each ->
    $(@).find('.nested-fields').each (i) ->
      $(@).find('.order').val(i + 1)

  $('.columns').each ->
    $(@).find('.nested-fields').each (i) ->
      $(@).find('.order').val(i + 1)

window.init_infinite_scroll = (ids) ->
  window.loading = false

  for id in ids
    do (id) ->
      $("##{ id }").scroll (e) ->
        url = $("##{ id }").find('.next_page_infinite_scroll').attr('href')

        if window.loading == false && url && ($(@).scrollTop() + $(@).innerHeight() >= $(@)[0].scrollHeight)
          window.loading = true

          $.getScript(url)

init_functions = ->
  init_tags()

  init_sortable()

$ ->
  init_functions()

$(window).bind 'page:load', ->
  init_functions()
