
{CompositeDisposable} = require 'atom'
FilesPopup = require './filesPopup'
_ = require 'lodash'

module.exports = EnhancedTabs =
  subscriptions: null
  openedTabs: []
  active: false
  popup: null
  activeTab: null

  activate: (state) ->
    editor = atom.workspace.getActiveTextEditor()
    @popup = new FilesPopup(editor);
    @activeTab =
      title: editor.getLongTitle()
      URI: editor.getURI()
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'enhanced-tabs:toggle': => @toggle()


    @subscriptions.add atom.workspace.observeTextEditors (editor)=>
      title = editor.getLongTitle()
      URI = editor.getURI()
      # skiping new files
      if (URI == undefined)
        return;
      if URI == @activeTab.URI
        @addToOpenedTabs(title: title, URI: URI)
      else
        @openedTabs.push(title: title, URI: URI)

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item)=>
      return unless item
      title = item.getLongTitle?()
      URI = item.getURI?()
      return unless title && URI
      @addToOpenedTabs(@activeTab)
      @activeTab =
        title: title
        URI: URI

    @subscriptions.add atom.workspace.onDidDestroyPaneItem (event)=>
      URI = event.item.getURI?()
      _.remove(@openedTabs, URI: URI)

  # openedTabs behaves as stack
  addToOpenedTabs: (elem)->
    _.remove(@openedTabs, URI: elem.URI)
    @openedTabs.splice(0, 0, elem)

  onkeyup: (event)->
    @onkeyup.first  = ++@onkeyup.first || 0
    switch event.keyCode
      when 9
        break unless @onkeyup.first > 1
        if (event.shiftKey)
          @popup.selectPreviousItemView()
        else
          @popup.selectNextItemView()
      when 17 then @popup.confirmSelection()
      # else @popup.cancel()

  registerCommandDispatcher: ->
    @onkeyup.first = 0;
    @listener = @onkeyup.bind(this);
    document.addEventListener 'keyup', @listener

  removeCommandDispatcher: ->
    document.removeEventListener 'keyup', @listener


  openedTabsMoveToTop: (elem)->
    return unless elem
    _.remove(@openedTabs, URI: elem.URI)
    @openedTabs.push(elem)


  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    enhancedTabsViewState: @enhancedTabsView.serialize()

  showTabsNav: ->
    @popup.setItems(@openedTabs);
    @popup.onConfirm = (item)=>
      atom.workspace.open(item.URI)
      @removeCommandDispatcher()
      @active = false
    @popup.toggle()
    @registerCommandDispatcher()
    @active = true;


  toggle: ->
    if (!@active)
      @showTabsNav();
