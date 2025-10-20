import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  PanResponder,
  PanResponderInstance,
  Pressable,
  StyleSheet,
  Text,
  View
} from 'react-native';

const GRID_SIZE = 18;
const HARMONY_MIN = 0;
const HARMONY_MAX = 6;
const MAX_PHASE_TURNS = 12;

type DirectionName = 'UP' | 'DOWN' | 'LEFT' | 'RIGHT';

type Direction = {
  x: number;
  y: number;
  name: DirectionName;
};

type Cell = {
  x: number;
  y: number;
};

type FoodType = 'ember' | 'tidal' | 'gale' | 'prism';

type Food = {
  position: Cell;
  type: FoodType;
};

const DIRECTIONS: Record<DirectionName, Direction> = {
  UP: { x: 0, y: -1, name: 'UP' },
  DOWN: { x: 0, y: 1, name: 'DOWN' },
  LEFT: { x: -1, y: 0, name: 'LEFT' },
  RIGHT: { x: 1, y: 0, name: 'RIGHT' }
};

const FOOD_CONFIG: Record<FoodType, {
  color: string;
  label: string;
  description: string;
  baseScore: number;
  bonusGrowth: number;
  mixBoost: number;
  repeatPenalty: number;
  phaseBonus: number;
}> = {
  ember: {
    color: '#ff6b6b',
    label: 'Ember Bloom',
    description: 'Supercharges growth but punishes repeats.',
    baseScore: 14,
    bonusGrowth: 1,
    mixBoost: 2,
    repeatPenalty: 2,
    phaseBonus: 0
  },
  tidal: {
    color: '#4d96ff',
    label: 'Tidal Pearl',
    description: 'Adds phase turns to slip through yourself.',
    baseScore: 16,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 1,
    phaseBonus: 2
  },
  gale: {
    color: '#3ad29f',
    label: 'Gale Petal',
    description: 'Keeps harmony steady and awards steady points.',
    baseScore: 12,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 0,
    phaseBonus: 0
  },
  prism: {
    color: '#b388ff',
    label: 'Prism Core',
    description: 'Refills harmony and grants long phasing.',
    baseScore: 32,
    bonusGrowth: 0,
    mixBoost: HARMONY_MAX,
    repeatPenalty: 0,
    phaseBonus: 6
  }
};

const FOOD_WEIGHTS: Array<[FoodType, number]> = [
  ['ember', 3],
  ['tidal', 3],
  ['gale', 4],
  ['prism', 1]
];

const createInitialSnake = (): Cell[] => {
  const center = Math.floor(GRID_SIZE / 2);
  return [
    { x: center + 1, y: center },
    { x: center, y: center },
    { x: center - 1, y: center }
  ];
};

const pickFoodType = (): FoodType => {
  const totalWeight = FOOD_WEIGHTS.reduce((sum, [, weight]) => sum + weight, 0);
  const target = Math.random() * totalWeight;
  let cumulative = 0;
  for (const [type, weight] of FOOD_WEIGHTS) {
    cumulative += weight;
    if (target <= cumulative) {
      return type;
    }
  }
  return 'gale';
};

const spawnFood = (snake: Cell[]): Food => {
  const occupied = new Set(snake.map((segment) => `${segment.x}-${segment.y}`));
  const freeCells: Cell[] = [];
  for (let y = 0; y < GRID_SIZE; y += 1) {
    for (let x = 0; x < GRID_SIZE; x += 1) {
      const key = `${x}-${y}`;
      if (!occupied.has(key)) {
        freeCells.push({ x, y });
      }
    }
  }

  if (freeCells.length === 0) {
    return { position: snake[0], type: 'prism' };
  }

  const position = freeCells[Math.floor(Math.random() * freeCells.length)];
  return { position, type: pickFoodType() };
};

const isOppositeDirection = (current: Direction, next: Direction) =>
  current.x + next.x === 0 && current.y + next.y === 0;

const useInterval = (callback: () => void, delay: number | null) => {
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (delay === null) {
      return undefined;
    }
    const id = setInterval(() => savedCallback.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
};

const Game: React.FC = () => {
  const [snake, setSnake] = useState<Cell[]>(() => createInitialSnake());
  const [food, setFood] = useState<Food>(() => spawnFood(createInitialSnake()));
  const [score, setScore] = useState(0);
  const [harmony, setHarmony] = useState(3);
  const [lastColor, setLastColor] = useState<FoodType | null>(null);
  const [phaseTurns, setPhaseTurns] = useState(0);
  const [isGameOver, setIsGameOver] = useState(false);

  const directionRef = useRef<Direction>(DIRECTIONS.RIGHT);
  const queuedDirectionRef = useRef<Direction>(DIRECTIONS.RIGHT);
  const growthRef = useRef(0);
  const phaseTurnsRef = useRef(0);
  const panResponderRef = useRef<PanResponderInstance>();

  useEffect(() => {
    phaseTurnsRef.current = phaseTurns;
  }, [phaseTurns]);

  const speed = useMemo(() => {
    const base = 230 - harmony * 25;
    return Math.max(80, base);
  }, [harmony]);

  const resetGame = useCallback(() => {
    const startingSnake = createInitialSnake();
    setSnake(startingSnake);
    setFood(spawnFood(startingSnake));
    setScore(0);
    setHarmony(3);
    setLastColor(null);
    setPhaseTurns(0);
    phaseTurnsRef.current = 0;
    growthRef.current = 0;
    directionRef.current = DIRECTIONS.RIGHT;
    queuedDirectionRef.current = DIRECTIONS.RIGHT;
    setIsGameOver(false);
  }, []);

  const handleFoodConsumption = useCallback(
    (type: FoodType, newSnake: Cell[]) => {
      setFood(spawnFood(newSnake));
      setScore((prev) => prev + FOOD_CONFIG[type].baseScore + harmony * 2);

      setHarmony((prevHarmony) => {
        if (type === 'prism') {
          return HARMONY_MAX;
        }
        if (lastColor === null) {
          return Math.min(HARMONY_MAX, prevHarmony + 1);
        }
        if (lastColor === type) {
          return Math.max(HARMONY_MIN, prevHarmony - FOOD_CONFIG[type].repeatPenalty);
        }
        return Math.min(HARMONY_MAX, prevHarmony + FOOD_CONFIG[type].mixBoost);
      });

      if (FOOD_CONFIG[type].phaseBonus > 0) {
        setPhaseTurns((prev) =>
          Math.min(MAX_PHASE_TURNS, prev + FOOD_CONFIG[type].phaseBonus)
        );
      }

      growthRef.current += FOOD_CONFIG[type].bonusGrowth;
      setLastColor(type);
    },
    [harmony, lastColor]
  );

  const tick = useCallback(() => {
    if (isGameOver) {
      return;
    }

    let consumedType: FoodType | null = null;
    let nextSnakeSnapshot: Cell[] = [];

    setSnake((prevSnake) => {
      if (prevSnake.length === 0) {
        return prevSnake;
      }

      directionRef.current = queuedDirectionRef.current;
      const currentDirection = directionRef.current;
      const head = prevSnake[0];
      const newHead: Cell = { x: head.x + currentDirection.x, y: head.y + currentDirection.y };

      if (
        newHead.x < 0 ||
        newHead.x >= GRID_SIZE ||
        newHead.y < 0 ||
        newHead.y >= GRID_SIZE
      ) {
        setIsGameOver(true);
        return prevSnake;
      }

      const intersectsBody = prevSnake.some(
        (segment, index) => index !== 0 && segment.x === newHead.x && segment.y === newHead.y
      );
      const phaseActive = phaseTurnsRef.current > 0;
      if (intersectsBody && !phaseActive) {
        setIsGameOver(true);
        return prevSnake;
      }

      const newSnake = [newHead, ...prevSnake];
      const hasEaten = food.position.x === newHead.x && food.position.y === newHead.y;

      if (hasEaten) {
        consumedType = food.type;
      }

      if (!hasEaten) {
        if (growthRef.current > 0) {
          growthRef.current -= 1;
        } else {
          newSnake.pop();
        }
      }

      nextSnakeSnapshot = newSnake;
      return newSnake;
    });

    if (consumedType && nextSnakeSnapshot.length > 0) {
      handleFoodConsumption(consumedType, nextSnakeSnapshot);
    } else if (phaseTurnsRef.current > 0) {
      setPhaseTurns((prev) => Math.max(0, prev - 1));
    }
  }, [food, handleFoodConsumption, isGameOver]);

  useInterval(tick, isGameOver ? null : speed);

  const trySetDirection = useCallback((next: Direction) => {
    const current = queuedDirectionRef.current;
    if (isOppositeDirection(current, next)) {
      return;
    }
    queuedDirectionRef.current = next;
  }, []);

  if (!panResponderRef.current) {
    panResponderRef.current = PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, gestureState) =>
        Math.abs(gestureState.dx) > 10 || Math.abs(gestureState.dy) > 10,
      onPanResponderRelease: (_, gesture) => {
        const { dx, dy } = gesture;
        if (Math.abs(dx) > Math.abs(dy)) {
          if (dx > 0) {
            trySetDirection(DIRECTIONS.RIGHT);
          } else {
            trySetDirection(DIRECTIONS.LEFT);
          }
        } else {
          if (dy > 0) {
            trySetDirection(DIRECTIONS.DOWN);
          } else {
            trySetDirection(DIRECTIONS.UP);
          }
        }
      }
    });
  }

  const harmonySegments = useMemo(
    () => Array.from({ length: HARMONY_MAX }, (_, i) => i < harmony),
    [harmony]
  );

  return (
    <View style={styles.wrapper} {...(panResponderRef.current?.panHandlers ?? {})}>
      <View style={styles.header}>
        <View style={styles.titleWrapper}>
          <Text style={styles.title}>Chromatic Current</Text>
          <Text style={styles.subtitle}>
            Keep your elemental harmony high by weaving between different blooms.
          </Text>
        </View>
        <View style={styles.scoreCard}>
          <Text style={styles.scoreLabel}>Score</Text>
          <Text style={styles.scoreValue}>{score}</Text>
          <Text style={styles.phaseLabel}>Phase {Math.max(0, phaseTurns)}</Text>
        </View>
      </View>

      <View style={styles.harmonyContainer}>
        <Text style={styles.harmonyLabel}>Harmony</Text>
        <View style={styles.harmonyTrack}>
          {harmonySegments.map((filled, index) => (
            <View
              // eslint-disable-next-line react/no-array-index-key
              key={index}
              style={[
                styles.harmonySegment,
                filled && styles.harmonySegmentFilled,
                index < harmonySegments.length - 1 && styles.harmonySegmentSpacing
              ]}
            />
          ))}
        </View>
        {lastColor && (
          <Text style={[styles.harmonyHint, { color: FOOD_CONFIG[lastColor].color }]}>
            Last: {FOOD_CONFIG[lastColor].label}
          </Text>
        )}
      </View>

      <View style={styles.boardWrapper}>
        <View style={styles.board}>
          {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, index) => {
            const x = index % GRID_SIZE;
            const y = Math.floor(index / GRID_SIZE);
            const isHead = snake[0] && snake[0].x === x && snake[0].y === y;
            const bodyIndex = snake.findIndex((segment) => segment.x === x && segment.y === y);
            const isBody = bodyIndex >= 0;
            const isFoodCell = food.position.x === x && food.position.y === y;

            return (
              <View
                key={`${x}-${y}`}
                style={[
                  styles.cell,
                  isBody && styles.snake,
                  isHead && styles.snakeHead,
                  isFoodCell && {
                    backgroundColor: FOOD_CONFIG[food.type].color,
                    borderColor: '#ffffff22'
                  }
                ]}
              />
            );
          })}
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerTitle}>Elemental Effects</Text>
        <View style={styles.legendRow}>
          {Object.entries(FOOD_CONFIG).map(([type, config]) => (
            <View key={type} style={styles.legendItem}>
              <View style={[styles.legendSwatch, { backgroundColor: config.color }]} />
              <View style={styles.legendTextWrapper}>
                <Text style={styles.legendTitle}>{config.label}</Text>
                <Text style={styles.legendDescription}>{config.description}</Text>
              </View>
            </View>
          ))}
        </View>
        <Text style={styles.tipText}>
          Matching colors repeatedly drains harmony. Fill the meter to speed up and gain
          bigger score bonuses!
        </Text>
      </View>

      {isGameOver && (
        <View style={styles.overlay}>
          <Text style={styles.overlayTitle}>Harmony Shattered</Text>
          <Text style={styles.overlaySubtitle}>Your chromatic current collapsed.</Text>
          <Pressable style={styles.retryButton} onPress={resetGame}>
            <Text style={styles.retryLabel}>Restart Run</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    flex: 1,
    backgroundColor: '#060913',
    borderRadius: 24,
    padding: 16,
    borderWidth: 1,
    borderColor: '#10182d'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12
  },
  titleWrapper: {
    flex: 1
  },
  title: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '700'
  },
  subtitle: {
    color: '#8f9bb5',
    marginTop: 4,
    lineHeight: 18
  },
  scoreCard: {
    backgroundColor: '#0d1324',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 16,
    alignItems: 'flex-end',
    borderWidth: 1,
    borderColor: '#1f2a4c',
    marginLeft: 12
  },
  scoreLabel: {
    color: '#6c7aa1',
    fontSize: 12
  },
  scoreValue: {
    color: '#f7fbff',
    fontSize: 22,
    fontWeight: '700'
  },
  phaseLabel: {
    color: '#7dd3fc',
    fontSize: 12
  },
  harmonyContainer: {
    backgroundColor: '#0d1324',
    borderRadius: 18,
    padding: 12,
    borderWidth: 1,
    borderColor: '#1b243d',
    marginBottom: 12
  },
  harmonyLabel: {
    color: '#9bb5ff',
    fontWeight: '600',
    marginBottom: 6
  },
  harmonyTrack: {
    flexDirection: 'row'
  },
  harmonySegment: {
    flex: 1,
    height: 10,
    borderRadius: 4,
    backgroundColor: '#1a2542'
  },
  harmonySegmentSpacing: {
    marginRight: 6
  },
  harmonySegmentFilled: {
    backgroundColor: '#61dbff'
  },
  harmonyHint: {
    marginTop: 6,
    color: '#ffffffaa',
    fontSize: 12,
    fontWeight: '500'
  },
  boardWrapper: {
    flex: 1,
    backgroundColor: '#05070f',
    borderRadius: 24,
    padding: 12,
    borderWidth: 1,
    borderColor: '#10182d',
    marginBottom: 12
  },
  board: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: '#05070f',
    borderRadius: 16,
    overflow: 'hidden'
  },
  cell: {
    width: `${100 / GRID_SIZE}%`,
    aspectRatio: 1,
    borderWidth: 0.5,
    borderColor: '#0b1329',
    backgroundColor: '#070b18'
  },
  snake: {
    backgroundColor: '#32e0c4',
    borderColor: '#22b498'
  },
  snakeHead: {
    backgroundColor: '#61dbff',
    borderColor: '#9bf6ff'
  },
  footer: {
    backgroundColor: '#0d1324',
    borderRadius: 18,
    padding: 12,
    borderWidth: 1,
    borderColor: '#1f2a4c'
  },
  footerTitle: {
    color: '#f7fbff',
    fontWeight: '600',
    fontSize: 16,
    marginBottom: 8
  },
  legendRow: {
    marginBottom: 8
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8
  },
  legendSwatch: {
    width: 20,
    height: 20,
    borderRadius: 6,
    marginRight: 12
  },
  legendTextWrapper: {
    flex: 1
  },
  legendTitle: {
    color: '#ffffff',
    fontWeight: '600'
  },
  legendDescription: {
    color: '#8f9bb5',
    fontSize: 12
  },
  tipText: {
    color: '#6c7aa1',
    fontSize: 12,
    marginTop: 4
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#05070fcc',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24
  },
  overlayTitle: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 6
  },
  overlaySubtitle: {
    color: '#9bb5ff',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 16
  },
  retryButton: {
    backgroundColor: '#61dbff',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 999
  },
  retryLabel: {
    color: '#05070f',
    fontWeight: '700'
  }
});

export default Game;
