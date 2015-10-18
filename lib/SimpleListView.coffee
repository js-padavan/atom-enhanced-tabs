{$, $$, View} = require 'atom-space-pen-views'
# _ = require 'underscore-plus'

Keys =
  Escape: 27
  Enter: 13
  Tab: 9

class SimpleSelectListView extends View
  maxItems: 10
  @content: ->
    @div class: "select-list", =>
      @ol class: "list-group", outlet: "list"

  # Private: Listens to events, delegates them to instance methods
  initialize: ->

    # List mouse events
    @list.on "mousedown", "li", (e) =>
      e.preventDefault()
      e.stopPropagation()

      view = $(e.target).closest("li")
      item = @findItemFromView view
      if item
        itemIndex = @items.indexOf item
        if itemIndex >= 0
          @curIndex = itemIndex
          @selectItemView view

    @list.on "mouseup", "li", (e) =>
      e.preventDefault()
      e.stopPropagation()

      if $(e.target).closest("li").hasClass "selected"
        @confirmSelection()

  # Private: Selects the previous item view
  selectPreviousItemView: =>
    @curIndex--;
    view = @getSelectedItemView().prev()
    unless view.length
      view = @list.find "li:last"
      @curIndex = @items.length - 1;
    @selectItemView view

    return false

  # Private: Selects the next item view
  selectNextItemView: =>
    @curIndex++;
    view = @getSelectedItemView().next()
    unless view.length
      view = @list.find "li:first"
      @curIndex = 0;
    @selectItemView view

    return false

  # Private: Sets the items, displays the list
  #
  # items - {Array} of items to display
  setItems: (items=[]) ->
    @items = items
    @populateList()

  # Private: Searches the items array for the item corresponding to the view
  #
  # view - the {jQuery} view to be selected
  findItemFromView: (view) ->
    return unless view.length
    viewText = view.text().trim()
    items = @items.filter (item) ->
      item.title == viewText
    return items[0]

  # Private: Unselects all views, selects the given view
  #
  # view - the {jQuery} view to be selected
  selectItemView: (view) ->
    return unless view.length

    @list.find(".selected").removeClass "selected"
    view.addClass "selected"
    @scrollToItemView view

  # Private: Sets the scroll position to match the given view's position
  #
  # view - the {jQuery} view to scroll to
  scrollToItemView: (view) ->
    scrollTop = @list.scrollTop()
    desiredTop = view.position().top + scrollTop
    desiredBottom = desiredTop + view.outerHeight()

    if desiredTop < scrollTop
      @list.scrollTop desiredTop
    else
      @list.scrollBottom desiredBottom

  # Private: Get the currently selected item view
  #
  # Returns the selected {jQuery} view
  getSelectedItemView: ->
    @list.find "li.selected"

  # Private: Get the currently selected item (*not* the view)
  #
  # Returns the selected {Object}
  getSelectedItem: ->
    @items[@curIndex]
  # Private: Confirms the currently selected item or cancels the list view
  # if no item has been selected
  confirmSelection: =>
    item = @getSelectedItem()
    if item?
      @confirmed item
      @cancel()
    else
      @cancel()

  attached:->
    @active = true


  # Private: Re-builds the list with the current items
  populateList: ->
    return unless @items?

    @list.empty()
    for i in [0...Math.min(@items.length, @maxItems)]
      item = @items[i]
      itemView = @viewForItem item
      @list.append itemView

    @selectItemView @list.find "li:first"
    @curIndex = 0;

  # Private: Creates a view for the given item
  #
  # word - the item
  #
  # Returns the {jQuery} view for the item
  viewForItem: ({word}) ->
    $$ ->
      @li =>
        @span word

  # Private: Clears the list, detaches the element
  cancel: ->
    return unless @active
    @active = false
    @list.empty()
    # @detach()

module.exports = SimpleSelectListView
