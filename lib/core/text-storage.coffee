LineIndex = require './line-index'
RunIndex = require './run-index'
{Emitter} = require 'atom'
Rope = require './rope'

class TextStorage

  stringStore: null
  runIndex: null
  lineIndex: null
  emitter: null

  constructor: (text='') ->
    if text instanceof TextStorage
      @rope = text.getString()
      @runIndex = text.runIndex?.cloneIndex()
    else
      @rope = text

  clone: ->
    clone = new TextStorage(@string)
    clone.runIndex = @runIndex?.clone()
    clone.lineIndex = @lineIndex?.clone()
    clone

  destroy: ->
    unless @destroyed
      @destroyed = true
      @runIndex?.destroy()
      @lineIndex?.destroy()
      @emitter?.emit 'did-destroy'

  ###
  Section: Events
  ###

  _getEmitter: ->
    unless emitter = @emitter
      @emitter = emitter = new Emitter
    emitter

  onDidBeginChanges: (callback) ->
    @_getEmitter().on 'did-begin-changes', callback

  onWillChange: (callback) ->
    @_getEmitter().on 'will-change', callback

  onDidChange: (callback) ->
    @_getEmitter().on 'did-change', callback

  onDidEndChanges: (callback) ->
    @_getEmitter().on 'did-end-changes', callback

  onDidDestroy: (callback) ->
    @_getEmitter().on 'did-destroy', callback

  ###
  String
  ###

  getString: ->
    @rope.toString()

  getLength: ->
    @rope.length

  string: null
  Object.defineProperty @::, 'string',
    get: -> @rope.toString()

  length: null
  Object.defineProperty @::, 'length',
    get: -> @rope.length

  substring: (start, end) ->
    @rope.substring(start, end)

  substr: (start, length) ->
    @rope.substr(start, length)

  charAt: (position) ->
    @rope.charAt(position)

  charCodeAt: (position) ->
    @rope.charCodeAt(position)

  deleteRange: (location, length) ->
    unless length
      return
    unless @rope.remove
      @rope = new Rope(@rope)
      @lineIndex?.string = @rope
    @rope.remove(location, location + length)
    @runIndex?.deleteRange(location, length)
    @lineIndex?.deleteRange(location, length)

  insertString: (location, text) ->
    unless text
      return

    unless @rope.insert
      @rope = new Rope(@rope)
      @lineIndex?.string = @rope
    text = text.split(/\u000d(?:\u000a)?|\u000a|\u2029|\u000c|\u0085/).join('\n')
    @rope.insert(location, text)
    @runIndex?.insertString(location, text)
    @lineIndex?.insertString(location, text)

  replaceRangeWithString: (location, length, string) ->
    @insertString(location, string)
    @deleteRange(location + string.length, length)

  ###
  Attributes
  ###

  _getRunIndex: ->
    unless runIndex = @runIndex
      @runIndex = runIndex = new RunIndex
      @runIndex.insertString(0, @rope.toString())
    runIndex

  getRuns: ->
    if @runIndex
      @runIndex.getRuns()
    else
      []

  getAttributesAtIndex: (index, effectiveRange, longestEffectiveRange) ->
    @_getRunIndex().getAttributesAtIndex(index, effectiveRange, longestEffectiveRange)

  getAttributeAtIndex: (attribute, index, effectiveRange, longestEffectiveRange) ->
    @_getRunIndex().getAttributeAtIndex(attribute, index, effectiveRange, longestEffectiveRange)

  setAttributesInRange: (attributes, index, length) ->
    @_getRunIndex().setAttributesInRange(attributes, index, length)

  addAttributeInRange: (attribute, value, index, length) ->
    @_getRunIndex().addAttributeInRange(attribute, value, index, length)

  addAttributesInRange: (attributes, index, length) ->
    @_getRunIndex().addAttributesInRange(attributes, index, length)

  removeAttributeInRange: (attribute, index, length) ->
    if @runIndex
      @runIndex.removeAttributeInRange(attribute, index, length)

  ###
  String and attributes
  ###

  subtextStorage: (location, length) ->
    unless length
      return new TextStorage('')
    subtextStorage = new TextStorage(@rope.substr(location, length))
    if @runIndex
      slice = @runIndex.sliceSpansToRange(location, length)
      insertRuns = []
      @runIndex.iterateRuns slice.spanIndex, slice.count, (run) ->
        insertRuns.push(run.clone())
      subtextStorage._getRunIndex().replaceSpansFromLocation(0, insertRuns)
    subtextStorage

  appendTextStorage: (textStorage) ->
    @insertTextStorage(@rope.length, textStorage)

  insertTextStorage: (location, textStorage) ->
    unless textStorage.length
      return
    @insertString(location, textStorage.getString())
    @setAttributesInRange({}, location, textStorage.getLength())
    if otherRunIndex = textStorage.runIndex
      insertRuns = []
      otherRunIndex.iterateRuns 0, otherRunIndex.getRunCount(), (run) ->
        insertRuns.push(run.clone())
      @_getRunIndex().replaceSpansFromLocation(location, insertRuns)

  replaceRangeWithTextStorage: (location, length, textStorage) ->
    @deleteRange(location, length)
    @insertTextStorage(location, textStorage)

  ###
  Lines
  ###

  _getLineIndex: ->
    unless lineIndex = @lineIndex
      @lineIndex = lineIndex = new LineIndex
      @lineIndex.insertString(0, @rope.toString())
    lineIndex

  getLineCount: ->
    @_getLineIndex().getLineCount()

  getLine: (row) ->
    @_getLineIndex().getLine(row)

  getRow: (line) ->
    @_getLineIndex().getLineIndex(line)

  getLines: (row, count) ->
    @_getLineIndex().getLines(row, count)

  iterateLines: (row, count, operation) ->
    @_getLineIndex().iterateLines(row, count, operation)

  ###
  Debug
  ###

  toString: ->
    "lines: #{@_getLineIndex().toString()} runs: #{@_getRunIndex().toString()}"

module.exports = TextStorage
