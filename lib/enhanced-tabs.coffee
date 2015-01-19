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
    editor = atom.workspace.getActiveEditor()
    @popup = new FilesPopup(editor);
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'enhanced-tabs:toggle': => @toggle()


    @subscriptions.add atom.workspace.observeTextEditors (editor)=>
      title = editor.getLongTitle()
      URI = editor.getURI()
      console.log('observed ', URI)
      @updateOpenedTab(title: title, URI: URI)

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item)=>
      title = item.getLongTitle?()
      URI = item.getURI?()
      return unless title && URI
      console.log('changed ', URI)
      console.dir(@openedTabs);
      @updateOpenedTab(title: title, URI: URI)
      # openedTabsMoveToTop(@activeTab)
      # @activeTab = title: title, URI: URI

    @subscriptions.add atom.workspace.onDidDestroyPaneItem (event)=>
      URI = event.item.getURI?()
      console.log('destoroyed', URI)
      _.remove(@openedTabs, URI: URI)

  onkeyup: (event)->
    @onkeyup.first  = ++@onkeyup.first || 0
    switch event.keyCode
      when 9
        if (@onkeyup.first > 1)
          @popup.selectNextItemView()
      when 17 then @popup.confirmSelection()
      # else @popup.cancel()

  registerCommandDispatcher: ->
    @onkeyup.first = 0;
    @listener = @onkeyup.bind(this);
    document.addEventListener 'keyup', @listener

  removeCommandDispatcher: ->
    document.removeEventListener 'keyup', @listener

  updateOpenedTab: (elem)->
    _.remove(@openedTabs, URI: elem.URI)
    @openedTabs.splice(@openedTabs.length - 1, 0, elem)

  openedTabsMoveToTop: (elem)->
    return unless elem
    _.remove(@openedTabs, URI: elem.URI)
    @openedTabs.push(elem)


  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    enhancedTabsViewState: @enhancedTabsView.serialize()

  showTabsNav: ->
    @popup.setItems(Array.prototype.slice.call(@openedTabs).reverse());
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
