path = require 'path'
SimpleSelectListView = require './SimpleListView'
{CompositeDisposable} = require 'event-kit'

class FilesPopup extends SimpleSelectListView
  visible: false
  panel: null

  initialize:  (@editor)->
    console.log 'popupinit with', @editor, arguments
    super
    @editorView = atom.views.getView(@editor)
    @addClass('enhanced-tabs-popup')
    @onConfirm = undefined;


    @panel = atom.workspace.addModalPanel(item: this, visible: false);
    @compositeDisposable = new CompositeDisposable
    # @compositeDisposable.add atom.commands.add '.atom-css-class-checker-popup',
      # "enhanced-tabs:confirm": @confirmSelection,
      # "enhanced-tabs:select-next": @selectNextItemView,
      # "atom-css-class-checker:select-previous": @selectPreviousItemView,
      # "enhanced-tabs:cancel": @cancel

  viewForItem: (item)->
    "<li>
      <div class='sel'>#{item.title}</div>
    </li>"

  confirmed: (item)->
    @onConfirm?(item)

  selectNextItemView: ->
    super
    false

  selectPreviousItemView: ->
    super
    false

  # constructor: (serializeState) ->
  #
  #   # test = @div class: 'panel, bordered'
  #   console.log 'test'
  #   console.log atom.workspaceView
  #
  #   # Register command that toggles this view
  #   atom.commands.add 'atom-workspace', 'atom-package:toggle': => @toggle()

  # # Returns an object that can be retrieved when package is activated
  # serialize: ->
  #
  # # Tear down any state and detach
  # destroy: ->


  attach: ->
    console.log 'attached called';
    # cursorMarker = @editor.getLastCursor().getMarker()
    # @overlayDecoration = @editor.decorateMarker(cursorMarker, type: 'overlay', position: 'tail', item: this)
    @visible = true
    @panel.show()

  # Toggle the visibility of this view
  toggle: ->
    if @visible
      @cancel()
    else
      @attach()


  cancel: =>
    # console.log 'cancel called';
    # return unless @active
    console.log 'active passed';
    @visible = false;
    # @overlayDecoration?.destroy()
    # @overlayDecoration = undefined
    @compositeDisposable.dispose()
    @panel.hide()
    super
    unless @editorView.hasFocus()
      @editorView.focus()



module.exports = FilesPopup
