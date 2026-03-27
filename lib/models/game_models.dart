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
      return _toLine(captures[_random.nextInt(captures.length)]);
    }

    if (currentLines.length < (gridSize * gridSize * 0.25)) {
      List<Move> openings = allPossible.where((m) {
        bool isEdge = m.r1 == 0 || m.r1 == gridSize - 1 || m.c1 == 0 || m.c1 == gridSize - 1;
        return isEdge && _getAffectedBoxes(m, boxes).every((b) => _countSides(b, currentLines) == 0);
      }).toList();
      
      if (openings.isNotEmpty) {
        return _toLine(openings[_random.nextInt(openings.length)]);
      }
    }

    List<Move> safeMoves = allPossible.where((m) {
      return _getAffectedBoxes(m, boxes).every((box) => _countSides(box, currentLines) < 2);
    }).toList();

    if (safeMoves.isNotEmpty) {
      safeMoves.shuffle();
      List<Move> superSafe = safeMoves.where((m) => 
        _getAffectedBoxes(m, boxes).every((box) => _countSides(box, currentLines) == 0)
      ).toList();
      
      return _toLine(superSafe.isNotEmpty ? superSafe[0] : safeMoves[0]);
    }

    allPossible.sort((a, b) {
      int lossA = _calculateChainLoss(a, currentLines, boxes);
      int lossB = _calculateChainLoss(b, currentLines, boxes);
      if (lossA == lossB) return _random.nextBool() ? -1 : 1;
      return lossA.compareTo(lossB);
    });

    return _toLine(allPossible.first);
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