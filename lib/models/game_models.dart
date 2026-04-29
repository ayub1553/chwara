// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Move {
  final int r1, c1, r2, c2;
  Move(this.r1, this.c1, this.r2, this.c2);
}

class Line {
  final int r1, c1, r2, c2;
  final Color color;
  final AnimationController controller;
  Line(this.r1, this.c1, this.r2, this.c2, this.color, this.controller);
}

class Box {
  final int r, c;
  final AnimationController controller;
  int? owner;
  Box(this.r, this.c, this.controller);

  bool checkComplete(List<Line> lines) {
    bool has(int r1, int c1, int r2, int c2) =>
        lines.any((l) => (l.r1 == r1 && l.c1 == c1 && l.r2 == r2 && l.c2 == c2) ||
                         (l.r1 == r2 && l.c1 == c2 && l.r2 == r1 && l.c2 == c1));
    return has(r, c, r, c + 1) &&
        has(r + 1, c, r + 1, c + 1) &&
        has(r, c, r + 1, c) &&
        has(r, c + 1, r + 1, c + 1);
  }
}

class DotsAI {
  final int gridSize;
  final TickerProvider vsync;
  final Random _random = Random();

  DotsAI(this.gridSize, this.vsync);

  Line? getBestMove(List<Line> currentLines, List<Box> boxes) {
    List<Move> allPossible = _getAllPossibleMoves(currentLines);
    if (allPossible.isEmpty) return null;

    List<Move> captures = allPossible.where((m) => _completesAnyBox(m, currentLines, boxes)).toList();
    
    if (captures.isNotEmpty) {
      Move? stubbornMove = _checkForDoubleCross(captures, currentLines, boxes, allPossible);
      if (stubbornMove != null) {
        return _toLine(stubbornMove);
      }

      List<Move> smartCaptures = captures.where((m) => !_isGivingAwayControl(m, currentLines, boxes)).toList();
      Move chosenMove = smartCaptures.isNotEmpty 
          ? smartCaptures[_random.nextInt(smartCaptures.length)] 
          : captures[_random.nextInt(captures.length)];
          
      return _toLine(chosenMove);
    }

    List<Move> safeMoves = allPossible.where((m) => 
      _getAffectedBoxes(m, boxes).every((box) => _countSides(box, currentLines) < 2)
    ).toList();

    if (safeMoves.isNotEmpty) {
      safeMoves.shuffle();
      return _toLine(safeMoves[0]);
    }

    allPossible.sort((a, b) => _calculateChainLoss(a, currentLines, boxes).compareTo(_calculateChainLoss(b, currentLines, boxes)));
    return _toLine(allPossible.first);
  }

  Move? _checkForDoubleCross(List<Move> captures, List<Line> currentLines, List<Box> boxes, List<Move> allPossible) {
    for (var m in captures) {
      List<Line> simLines = List.from(currentLines)..add(_toLine(m));
      
      int chainLength = 1;
      List<Line> chainSim = List.from(simLines);
      bool foundMore;
      do {
        foundMore = false;
        var nextCaptures = _getAllPossibleMoves(chainSim)
            .where((nm) => _completesAnyBox(nm, chainSim, boxes)).toList();
        if (nextCaptures.isNotEmpty) {
          chainSim.add(_toLine(nextCaptures.first));
          chainLength++;
          foundMore = true;
        }
      } while (foundMore);

      if (chainLength >= 2) {
        var currentChainCaptures = allPossible.where((nm) => _completesAnyBox(nm, currentLines, boxes)).toList();
        
        if (currentChainCaptures.length <= 2) {
          List<Move> throwAwayMoves = allPossible.where((tm) => 
            !_completesAnyBox(tm, currentLines, boxes) && 
            _getAffectedBoxes(tm, boxes).every((b) => _countSides(b, currentLines) < 2)
          ).toList();

          if (throwAwayMoves.isNotEmpty) {
            return throwAwayMoves[_random.nextInt(throwAwayMoves.length)];
          }
        }
      }
    }
    return null;
  }
  int _calculateMinLossAfterChain(Move m, List<Line> currentLines, List<Box> boxes) {
    List<Line> simLines = List.from(currentLines)..add(_toLine(m));
    while (true) {
      List<Move> chainMoves = _getAllPossibleMoves(simLines).where((nm) => _completesAnyBox(nm, simLines, boxes)).toList();
      if (chainMoves.isEmpty) break;
      simLines.add(_toLine(chainMoves.first));
    }
    List<Move> remaining = _getAllPossibleMoves(simLines);
    if (remaining.isEmpty) return 0;
    remaining.sort((a, b) => _calculateChainLoss(a, simLines, boxes).compareTo(_calculateChainLoss(b, simLines, boxes)));
    return _calculateChainLoss(remaining.first, simLines, boxes);
  }

  bool _isGivingAwayControl(Move m, List<Line> currentLines, List<Box> boxes) {
    List<Line> simLines = List.from(currentLines)..add(_toLine(m));
    List<Move> nextPossible = _getAllPossibleMoves(simLines);
    if (nextPossible.isEmpty) return false;
    return nextPossible.every((nextMove) => _calculateChainLoss(nextMove, simLines, boxes) > 2);
  }

  int _calculateChainLoss(Move m, List<Line> currentLines, List<Box> boxes) {
    List<Line> simLines = List.from(currentLines);
    simLines.add(_toLine(m));
    int score = 0;
    bool found;
    
    do {
      found = false;
      for (var box in boxes) {
        if (_countSides(box, simLines) == 3) {
          _simulateBoxCompletion(box, simLines);
          score++;
          found = true;
          break;
        }
      }
    } while (found);
    return score;
  }

  void _simulateBoxCompletion(Box b, List<Line> lines) {
    if (!_exists(b.r, b.c, b.r, b.c + 1, lines)) lines.add(_toLine(Move(b.r, b.c, b.r, b.c + 1)));
    else if (!_exists(b.r + 1, b.c, b.r + 1, b.c + 1, lines)) lines.add(_toLine(Move(b.r + 1, b.c, b.r + 1, b.c + 1)));
    else if (!_exists(b.r, b.c, b.r + 1, b.c, lines)) lines.add(_toLine(Move(b.r, b.c, b.r + 1, b.c)));
    else if (!_exists(b.r, b.c + 1, b.r + 1, b.c + 1, lines)) lines.add(_toLine(Move(b.r, b.c + 1, b.r + 1, b.c + 1)));
  }

  List<Move> _getAllPossibleMoves(List<Line> lines) {
    List<Move> moves = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (j < gridSize - 1 && !_exists(i, j, i, j + 1, lines)) moves.add(Move(i, j, i, j + 1));
        if (i < gridSize - 1 && !_exists(i, j, i + 1, j, lines)) moves.add(Move(i, j, i + 1, j));
      }
    }
    return moves;
  }

  bool _exists(int r1, int c1, int r2, int c2, List<Line> lines) =>
      lines.any((l) => (l.r1 == r1 && l.c1 == c1 && l.r2 == r2 && l.c2 == c2) ||
                       (l.r1 == r2 && l.c1 == c2 && l.r2 == r1 && l.c2 == c1));

  int _countSides(Box box, List<Line> lines) {
    int s = 0;
    if (_exists(box.r, box.c, box.r, box.c + 1, lines)) s++;
    if (_exists(box.r + 1, box.c, box.r + 1, box.c + 1, lines)) s++;
    if (_exists(box.r, box.c, box.r + 1, box.c, lines)) s++;
    if (_exists(box.r, box.c + 1, box.r + 1, box.c + 1, lines)) s++;
    return s;
  }

  bool _completesAnyBox(Move m, List<Line> lines, List<Box> boxes) =>
      _getAffectedBoxes(m, boxes).any((box) => _countSides(box, lines) == 3);

  List<Box> _getAffectedBoxes(Move m, List<Box> boxes) => boxes.where((b) {
        if (m.r1 == m.r2) return (b.r == m.r1 || b.r == m.r1 - 1) && b.c == m.c1;
        return b.r == m.r1 && (b.c == m.c1 || b.c == m.c1 - 1);
      }).toList();

  Line _toLine(Move m) => Line(m.r1, m.c1, m.r2, m.c2, Colors.red,
      AnimationController(vsync: vsync, duration: Duration.zero));
}

class TestVSync implements TickerProvider {
  const TestVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}