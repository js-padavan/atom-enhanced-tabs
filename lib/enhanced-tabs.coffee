{CompositeDisposable} = require 'atom'
FilesPopup = require './filesPopup'
_ = require 'lodash'

module.exports = EnhancedTabs =
  subscriptions: null
  openedTabs: []
  active: false
  popup: null
  activeTab: null
  initialized: false

  activate: (state) ->
    editor = atom.workspace.getActiveTextEditor()
    if (editor)
      @popup = new FilesPopup(editor);
      @activeTab =
        title: editor.getLongTitle?() || editor.getTitle?()
        URI: editor.getURI()
      initialized = true;
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'enhanced-tabs:toggle', (e) => @toggle(e)


    @subscriptions.add atom.workspace.observeTextEditors (editor)=>
      if (!initialized && editor)
        @popup = new FilesPopup(editor);
        @activeTab =
          title: editor.getLongTitle?() || editor.getTitle?()
          URI: editor.getURI()
        initialized = true;
      if (!editor)
        return;
      title = editor.getLongTitle?() || editor.getTitle?()
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
      title = item.getLongTitle?() || item.getTitle?()
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
        event.stopImmediatePropagation();
      when 17
        if @active
          @popup.confirmSelection()
        event.stopImmediatePropagation();
      when 27
        @cancelPopup()
        event.stopImmediatePropagation();


      # else @popup.cancel()

  onclick: (event) ->
    # this will only run when clicking away from the list
    # because the click handler on SimpleListView does a stopPropagation()
    @cancelPopup()

  cancelPopup: ->
    if @popup
      @popup.cancel()
      @removeCommandDispatcher()
      @active = false

  registerCommandDispatcher: ->
    @onkeyup.first = 0;
    @listenerKeyup = @onkeyup.bind(this);
    @listenerClick = @onclick.bind(this);
    document.body.addEventListener 'keyup', @listenerKeyup
    document.body.addEventListener 'click', @listenerClick

  removeCommandDispatcher: ->
    document.body.removeEventListener 'keyup', @listenerKeyup
    document.body.removeEventListener 'click', @listenerClick


  openedTabsMoveToTop: (elem)->
    return unless elem
    _.remove(@openedTabs, URI: elem.URI)
    @openedTabs.push(elem)


  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    # console.log(@enhancedTabsView);
    # enhancedTabsViewState: @enhancedTabsView.serialize();

  showTabsNav: ->
    if (!@popup)
      return;
    items =_.filter( @openedTabs
            (item)->
              console.log(item.URI)
              return item.URI != @activeTab.URI
            @)

    @popup.setItems(items);
    @popup.onConfirm = (item)=>
      atom.workspace.open(item.URI)
      @removeCommandDispatcher()
      @active = false
    @popup.toggle()
    @registerCommandDispatcher()
    @active = true;


  toggle: (e)->
    console.log('toggle called');
    e.stopImmediatePropagation();
    if (!@active)
      @showTabsNav();
    false;
