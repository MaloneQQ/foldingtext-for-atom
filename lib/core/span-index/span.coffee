_ = require 'underscore-plus'

class Span

  @parent: null
  @string: ''

  constructor: (@string='') ->

  clone: ->
    new @constructor(@string)

  split: (location) ->
    if location is 0 or location is @getLength()
      return null

    clone = @clone()
    clone.setString(@string.substr(location))
    @setString(@string.substr(0, location))
    clone

  mergeWithSpan: (span) ->
    false

  ###
  Section: Characters
  ###

  getLocation: ->
    @parent.getLocation(this) or 0

  getLength: ->
    @string.length

  getString: ->
    @string

  setString: (string='') ->
    delta = (string.length - @string.length)
    @string = string
    if delta
      each = @parent
      while each
        each.length += delta
        each = each.parent
    @

  deleteRange: (location, length) ->
    newString = @string.slice(0, location) + @string.slice(location + length)
    @setString(newString)

  insertString: (location, text) ->
    newString = @string.substr(0, location) + text + @string.substr(location)
    @setString(newString)

  appendString: (string) ->
    @insertString(@getLength(), string)

  ###
  Section: Spans
  ###

  getSpanIndex: ->
    @parent.getSpanIndex(this)

  getSpanCount: ->
    1

  ###
  Section: Debug
  ###

  toString: (extra) ->
    if extra
      "(#{@string}/#{extra})"
    else
      "(#{@string})"

module.exports = Span