linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
{CompositeDisposable, Range, Point, BufferedProcess} = require 'atom'

class LinterChktex extends Linter
  # ConfigObserver.includeInto(this)

  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: 'text.tex.latex'

  # Set the current directory to the project path
  cwd: atom.project.getPaths() || @cwd

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: ['chktex', '-I0', '-wall', '-l.chktexrc', '-f%l:%c:%d %k %k %n: %m\\n']

  linterName: 'chktex'

  # A regex pattern used to extract information from the executable's output.
  regex:
    '^(?<line>\\d+):(?<col>\\d+):(?<colEnd>\\d+) (?:(?<error>Error)|(?<warning>Warning)) (?<message>.+)'
    #'^.+:(?<line>\\d+):(?<col>\\d+):(?<message>.*)$'

  regexFlags: 'm'

  constructor: (editor)->
    super(editor)

    @chktexExecutablePath = atom.config.observe 'linter-chktex.chktexExecutablePath', =>
      @executablePath = atom.config.get 'linter-chktex.chktexExecutablePath'

  processMessage: (message, callback) ->

    # chktex won't actually put newlines in (even with !n format)
    # split these fake newlines into real ones
    if message? and message.length > 0
      splitMessage = message.replace(/\\n/g, "\n")
    else
      # cover case where chktex produces no output on stdout
      super('', callback)
      return

    super(splitMessage, callback)


  computeRange: (match) ->

    # colEnd is just the length of the error starting from col
    # range is col + colEnd
    rowStart = parseInt(match.line, 10) - 1
    rowEnd = rowStart
    colStart = parseInt(match.col, 10) - 1
    colEnd = colStart + parseInt(match.colEnd, 10)

    return new Range(
      [rowStart, colStart],
      [rowEnd, colEnd]
    )

  destroy: ->
    @chktexExecutablePath.dispose()

module.exports = LinterChktex
