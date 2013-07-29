bindable = require "bindable"

class Node
  __isNode: true

class Container extends Node

  
  ###
  ###

  constructor: () ->
    @childNodes = []

  ###
  ###

  appendChild: (node) -> 

    # fragment?
    if node.nodeType is 11
      @appendChild(child) for child in node.childNodes.concat()  
      return

    @_unlink node
    @childNodes.push node
    @_link node

  ###
  ###

  removeChild: (child) ->
    i = @childNodes.indexOf child
    return unless ~i
    @childNodes.splice i, 1
    child.previousSibling?.nextSibling = child.nextSibling
    child.nextSibling?.previousSibling = child.previousSibling
    child.parentNode = child.nextSibling = child.previousSibling = undefined

  ###
  ###

  insertBefore: (newElement, before) ->

    if newElement.nodeType is 11
      for node in newElement.childNodes.concat().reverse()
        @insertBefore node, before
        before = node
      return

    @_splice @childNodes.indexOf(before), 0, newElement

  ###
  ###

  _splice: (index = -1, count, node) ->

    return unless ~index

    if node
      @_unlink node

    @childNodes.splice arguments...

    if node
      @_link node

  ###
  ###

  _unlink: (node) ->
    # remove from the previous parent
    if node.parentNode
      node.parentNode.removeChild node


  ###
  ###

  _link: (node) ->  

    unless node.__isNode
      throw new Error "cannot append non-node"

    node.parentNode = @
    i = @childNodes.indexOf node

    # FFox compatible
    node.previousSibling = if i isnt 0 then @childNodes[i - 1] else undefined
    node.nextSibling     = if i isnt @childNodes.length - 1 then @childNodes[i + 1] else undefined

    node.previousSibling?.nextSibling = node
    node.nextSibling?.previousSibling = node






class Element extends Container

  ###
  ###

  nodeType: 3

  ###
  ###

  constructor: (@nodeName) ->
    super()
    @attributes  = []
    @_attrsByKey = {}
    @style = {}

  ###
  ###

  setAttribute: (name, value) -> 

    if name is "style"
      @_parseStyle value

    if value is undefined
      return @removeAttribute name 

    unless (abk = @_attrsByKey[name])
      @attributes.push abk = @_attrsByKey[name] = { }

    abk.name  = name
    abk.value = value

  ###
  ###

  removeAttribute: (name) ->

    for attr, i in @attributes
      if attr.name is name
        @attributes.splice(i, 1)
        break

    delete @_attrsByKey[name]


  ###
  ###

  getAttribute: (name) -> @_attrsByKey[name]?.value

  ###
  ###

  toString: () ->
    buffer = ["<", @nodeName]
    attribs = []

    @_setStyleAttribute()

    for name of @_attrsByKey
      v = @_attrsByKey[name].value
      attrbuff = name
      if v?
        attrbuff += "=\""+v+"\""
      attribs.push attrbuff



    if attribs.length
      buffer.push " ", attribs.join " "

    buffer.push ">"
    buffer.push @childNodes...
    buffer.push "</", @nodeName, ">"

    buffer.join ""

  ###
  ###

  _setStyleAttribute: () ->

    buffer = []

    for key of @style
      continue unless @style[key]?
      buffer.push "#{key}:#{@style[key]}"

    return unless buffer.length

    @setAttribute "style", buffer.join(";") + ";"

  ###
  ###

  _parseStyle: (styles = "") ->

    newStyles = {}

    for style in styles.split(";")
      sp = style.split(":")
      continue unless sp[1]?
      newStyles[sp[0]] = sp[1]

    @style = newStyles






class Text extends Node

  ###
  ###

  nodeType: 3

  ###
  ###

  constructor: (@value) ->

  ###
  ###

  toString: () -> @value


class Comment extends Text
  
  ###
  ###

  nodeType: 8

  ###
  ###


  toString: () -> "<!--#{super()}-->"



class Fragment extends Container
  
  ###
  ###

  nodeType: 11

  ###
  ###

  toString: () -> @childNodes.join ""



class StringNodeFactory extends require("./base")

  ###
  ###

  constructor: (@context) -> 
    @internal = new bindable.Object()

  ###
  ###

  createElement: (name) -> new Element name

  ###
  ###

  createTextNode: (text) -> new Text text

  ###
  ###

  createComment: (text) -> new Comment text

  ###
  ###

  createFragment: () -> 
    frag = new Fragment()
    for child in arguments
      frag.appendChild child
    frag

  ###
  ###

  parseHtml: (buffer) -> 

    # this should really parse HTML, but too much overhead
    @createTextNode buffer


module.exports = new StringNodeFactory()