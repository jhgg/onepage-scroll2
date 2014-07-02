
$.fn.swipeEvents = ->
  $this = $ this
  startX = startY = 0

  touchStart = (e) ->
    e?.preventDefault()
    touches = e?.originalEvent?.touches
    return unless touches?.length

    startX = touches[0].pageX
    startY = touches[0].pageY

    $this.off 'touchmove', touchMove
    $this.on  'touchmove', touchMove


  touchMove = (e) ->
    e?.preventDefault()
    touches = e?.originalEvent?.touches
    return unless touches?.length

    deltaX = startX - touches[0].pageX
    deltaY = startY - touches[0].pageY

    trigger = (name) ->
      $this.trigger name
      $this.unbind 'touchmove', touchMove

    trigger 'swipeLeft'   if deltaX >= 50
    trigger 'swipeRight'  if deltaX <= -50
    trigger 'swipeUp'     if deltaY >= 50
    trigger 'swipeDown'   if deltaY <= -50

  $this.on 'touchstart', touchStart


class OnePageScroll

  _default_options:
    # The selector to use to find sections.
    sectionContainer: "section.row"
    # The selector to add the page list thing to
    pageListContainer: "body"
    # The easing function to use when scrolling between pages.
    easing: "ease"
    # How long in ms the page transition should occur.
    animationTime: 700
    # Whether the scrolling will loop.
    loop: false
    # Whether the up/down arrow should scroll the page.
    keyboard: true
    # Whether to show the navigation pills on the side of the page.
    pagination: true

  constructor: (options, el) ->
    # The options for this one page scroller.
    @options = $.extend {}, @_default_options, options

    # The current page index.
    @currentIndex = 0

    # The root element of the page scroller.
    @$el = $ el

    # All the sections that we will scroll
    @$sections = @$el.find @options.sectionContainer

    # Are we scrolling? Set to true/false in _transitionPage
    @isScrolling = false

    # An array of objects, containing sections & their metadata.
    @sections = @_buildSections()


    @_bindEvents()
    @_positionSections()
    @$pageList = @_buildPageList() if @options.pagination

  _buildSections: ->
    ({
      $el: $ section
      id: $(section).attr('id')
    } for section in @$sections)

  _bindEvents: ->
    @$el
      .swipeEvents()
      .bind('swipeDown', => @moveUp())
      .bind('swipeUp',   => @moveDown())


    if @options.keyboard
      # Arrow Up / Down will trigger a move if we're not typing in an input or textarea.
      $(document).keydown (e) =>

        tag = e?.target?.tagName?.toLowerCase()
        return if tag in ['input', 'textarea']

        switch e.which
          when 38, 33
            @moveUp()

          when 40, 34
            @moveDown()

          when 36
            @moveToIndex 0

          when 35
            @moveToIndex @sections.length - 1

          else
            return

        e.preventDefault()

    # Scrolling will change pages if we're not animating.
    $(document).bind 'mousewheel DOMMouseScroll', (e) =>
      e?.preventDefault()
      delta = e.originalEvent.wheelDelta or -e.originalEvent.detail;
      (if delta < 0 then @moveDown() else @moveUp()) unless @isScrolling


  _positionSections: ->
    topPos = 0

    @$el
      .addClass('onepage-wrapper')
      .css('position', 'relative')

    for section in @sections
      section.$el
        .addClass('section')
        .css
          position: 'absolute'
          top: "#{ topPos }%"

      topPos += 100

  _buildPageList: ->
    $ul = $("<ul></ul>").addClass 'onepage-pagination'

    for idx in [0...@sections.length]
      do (idx) =>
        $a = $ "<a></a>"
          .click (e) =>
            e.preventDefault()
            @_goToIndex idx

        $li = $ "<li></li>"
        $li.append $a
        $ul.append $li

    $ul.appendTo $ @options.pageListContainer
    $ul.find('li:first-of-type a').addClass('active')

    $ul

  _goToIndex: (index) ->
    return if @isScrolling or index is @currentIndex

    styles = {}
    pos = -100 * index

    for prefix in ['-webkit-', '-moz-', '-ms-', '']
      styles["#{ prefix }transform"] = "translateY(#{ pos }%)"
      styles["#{ prefix}transition"] = "all #{ @options.animationTime }ms #{ @options.easing }"

    @isScrolling = true
    @options.beforeMove?(index)

    if @options.pagination
      @$pageList.find('li a.active').removeClass('active')
      $(@$pageList.find('li a').get(index)).addClass('active')

    @$el
      .css styles
      .one 'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', =>
        @isScrolling = false
        @currentIndex = index
        @options.afterMove?(index)

  _getIndexForSectionById: (id) ->
    for i in [0...@sections.length]
      return i if @sections[i].id is id

    -1

  moveDown: ->
    nextIndex = @currentIndex + 1
    if not @sections[nextIndex]
      return unless @options.loop
      nextIndex = 0

    @_goToIndex(nextIndex)

  moveUp: ->
    nextIndex = @currentIndex - 1
    if not @sections[nextIndex]
      return unless @options.loop
      nextIndex = @sections.length - 1

    @_goToIndex(nextIndex)

  moveToIndex: (index) ->
    return unless @sections[index]
    @_goToIndex(index)

  moveToSectionWithId: (id) ->
    index = @_getIndexForSectionById id
    @moveToIndex index



$.fn.onePageScroll2 = (arg0, splat...) ->
  $this = $(this)
  onePageScroll = $this.data 'onePageScroll'

  if not onePageScroll
    onePageScroll = new OnePageScroll((if typeof arg0 is 'object' then arg0 else {}), $this)
    $this.data 'onePageScroll', onePageScroll

  onePageScroll[arg0]?(splat...) if typeof arg0 is 'string' and arg0.substr(0, 1) isnt '_'
  $this