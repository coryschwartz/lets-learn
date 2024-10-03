---
layout: post
title:  "Machine Learning Part 1"
date:   2024-10-02 17:53:49 +0000
categories: technology ML
---

# Naieve genetic algorithm

## I'm an idiot blurb:

If you're reading this and you think "hey, this isn't how this is supposed to work" You're probably right. At this phase, I have done zero research and I am just going for it.
This is by blue-sky thinking for how this should work, complete with code snippits. I will continue to refine this and then I'll do a little research and will write post about
what I learned, and how my naieve approach is different than conventional thinking. My understanding is wrong, my implementation is wrong. It's all wrong. Don't read this for knowledge.

## General stragegy:

In general, a genetic algorithm will have have a population swarm of individuals. Individuals are scored on their fitness at performing a task, and top performers are selected
for breeding. Each individual has a set of traits that can be passed on to their offspring, and these traits affect their performance. In a manor that is similar to natural selection,
we expect that the offspring with poor traits will be less likely to survive and reproduce and those with better traits go on to pass those genes to the next generation.

It is also a common pracitce to introduce random mutations to the offspring. The purpose of the random mutations is to prevent premature convergence on a false peak.

I want to have the rules of evolution encoded separately from the task the individuals are trying to perform. I ought to be able to change out the task and have the evolution system
adapt and evolve to the new task.


So to reiterate, I need to have the following components:

* A scoring/evaluation function
* Individual actors
  > with passable traits
* A selection function
* A breeding function
* A mutation function


# The game

Before I write the evolution system, I need to have a game to play, some way to score the individuals and determine their fitness.

There are a lot of videos and articles of people using their machine learning applications to play video games, or move robotic arms or other cool things. My system is not going to be
nearly that cool. I'm going for a system that has no graphics, no human interaction, just a bunch of little computer guys playing against each other.

It's going to be a simple challenge response game.

A number will be generated and passed to each of the individual players. The players will use its traits to process the number and will return a new number. The scorekeeper will look at each
resonse and will assign each player a score.

I think this game, simple as it is, has some fair analogies to the real world. I imagine that that the challenges might be a change in wind direction that pushes a robotic airplane. The response
is fed into the ailerons, and the success is calculated based on how well the airplane stays on course.

But like I said, this system is not that cool. In this system, my scorekeeper will be running a secret function and none of the other players know what the function is. The players will try to
predict what the secret function is, and they are scored according to how well their gueses match the secret function.


# Interfaces

I started off by defining the interfaces, I'm going to have a Player interface and a Scorer interface.


```go

type Player[T any] interface {
        Evaluate(input T) T
}

type Scorer[T any] interface {
        Score(input, guess T) float64
}
```

So you can probably see what I'm thinking here. You generate a challenge, pass it to `Player.Evaluate` to generate a guess. Then you pass the challenge and the guess to `Scorer.Score` to see the fitness of the guess.


# The player

The design of the player is really the design of the player's genes. I feel that it would be a good property for the player to have an arbitrary number of genes. My thinking is that players with more genes
will be capable of solving more complex problems. I imagine that the genes will encode a number of steps that will process over the data, so the first gene accepts the challenge as the input and the rest of the genes
accept the output of the previous gene. This way, each gene can be swapped out for another during the breeding process.

Finally, I think it would be good for the genes to be serializable. I dont want the genes to just be a function pointers, I want to be able to save them to disk and laod them back again if I want to. What good is
machine learning, if you can't save what you've learned?

The approach I decided to move forward with is a stack machine. To me, what makes a stack machine an attractive choice is that is that it's extremely simple to serialize and I can represent both function "pointers"
and data in the same way. When I get to the breeding process, I can swap out both functions and data the same way. Let me show you what I mean.


First I deinfed a set of "operations". These are functions that the stack machine knows how to perform.
These are pretty arbitrary, and I didn't spend a whole lot of time deciding what to include, but we have some basic mathematical operations that will make up our stack machine instruction set.

I chose to make these operations all take two operands, *left* and *right*. These values will be pulled off of the stack, and then the result will be pushed back onto the stack.

```go
var AllOperations = []Operation{
        AddOperation,
        SubtractOperation,
        MultiplyOperation,
        DivideOperation,
        ModOperation,
        XorOperation,
}

type Operation func(left, right int) int

func AddOperation(left, right int) int {
        return left + right
}

func SubtractOperation(left, right int) int {
        return left - right
}

func MultiplyOperation(left, right int) int {
        return left * right
}

func DivideOperation(left, right int) int {
        if right == 0 {
                return 0
        }
        return left / right
}

func ModOperation(left, right int) int {
        if right == 0 {
                return 0
        }
        return left % right
}

func XorOperation(left, right int) int {
        return left ^ right
}

```

and I wrote a simple stack structure capable of executing these operations

```go
type stack struct {
        elements []int
}

func (s *stack) Push(value int) {
        s.elements = append(s.elements, value)
}

func (s *stack) Pop() int {
        if len(s.elements) == 0 {
                return 0
        }
        value := s.elements[len(s.elements)-1]
        s.elements = s.elements[:len(s.elements)-1]
        return value
}

func (s *stack) Copy() *stack {
        newStack := NewStack()
        newStack.elements = make([]int, len(s.elements))
        copy(newStack.elements, s.elements)
        return newStack
}

func (s *stack) Evaluate() int {
        if len(s.elements) == 0 {
                return 0
        }
        if len(s.elements) == 1 {
                return s.elements[0]
        }
        right := s.Pop()
        left := s.Pop()
        oi := abs(s.Pop()) % len(AllOperations)
        op := AllOperations[oi]
        s.Push(op(left, right))
        return s.Evaluate()
}

func NewStack() *stack {
        return &stack{
                elements: []int{},
        }
}
```


All the magic is in that Evaluate() function. It pops two values off the stack and stores them as operands. It pops off another value and coerses it into an index for an operation in our instruction set.
The operation is executed, and pushed back onto the stack. Every time this runs, we are pulling off three values and pushing on one value, until the stack has only one value left. At that point,
the stack is evaluated, and the result is returned. This satifies all the qualities I wanted -- it's serializable, it's simple, and since it consists of nothing more than a slice of integers, it will be
easy to breed and mutate later on.

I'm not going to implement breeding today, but I did think about it a bit.  It's not clear to me whether it's better to consider each number an individual gene or if I should consider a pair of integers
(that is, the operation, and it's *left* operand) as a gene together. On one hand, maybe it's only important that you are multiplying. Or I might want to add new operations that take three operands rather than
the current two. This way, if each integer is a separate gene, this might be the most flexable solution. On the other hand, if you are multiplying by 100 in one generation and by -100
the next, we might lose our fitness or converge on a solution slower than if we transfer the operation and operand together. but that's a problem for another day.


With the stack machine in hand, I can now define what the player looks like.
The player, with it's stack machine genes, should accept a number, evaluate it, and return a number.

This code does exactly that in it's Evaluate function, and I have a constrctor that initializes the player with random genes.

```go

type StackMachinePlayer struct {
        s *stack
}

func (p *StackMachinePlayer) Evaluate(n int) int {
        cpy := p.s.Copy()
        cpy.Push(n)
        return cpy.Evaluate()
}

func NewStackMachinePlayer(size int) (*StackMachinePlayer, error) {
        s := NewStack()

        // We need to make sure our numbers can be scored as a float64,
        // without rounding errors.
        reallyBig := big.NewInt(math.MaxInt32)
        for i := 0; i < size; i++ {
                randBig, err := rand.Int(rand.Reader, reallyBig)
                if err != nil {
                        return nil, err
                }
                // sometimes make it negative.
                if mrand.Int()%2 == 0 {
                        randBig = randBig.Neg(randBig)
                }
                s.Push(int(randBig.Int64()))
        }
        return NewStackMachinePlayerWithStack(s), nil
}

func NewStackMachinePlayerWithStack(s *stack) *StackMachinePlayer {
        return &StackMachinePlayer{s: s}
}
```


# The scorer.

To end off for today, I wrote a simple scorer. My requirement for the scorer was was that it should be able to judge how well other player's guesses match the secret function.
I thought I might as well implement the secret function with my stack machine as well, so this implementation will have it's own player struct to evaluate the secret function.

The scorer takes a challenge and a guess. It evaluates the challenge with it's internal player, and then returns a float between 0 and 1 depending on how close the guess is to it's evaluation.
If the score is a 1, then the guess is perfect. The farther away the guess is from the evaluated result, the closer the score will be to 0.

It was a bit of a struggle to make this work. My initial implementaiton , although I think it was logically sound, was not working as expected. This was due to the precision of floating point numbers.
Rounding errors were kicking my butt for a few minutes. Anyway, so long as we are careful to limit the size of our integers, this tests out fine, and I'm going to set it down here and will pick it up
on a new day.

Maybe I should switch from an integer stack machine to int8 or something. I'll consider it for next time.


```go
type StackMachineScorer struct {
        player *StackMachinePlayer
}

// compare guess to the actual answer and return a score (0, 1]
func (g *StackMachineScorer) Score(input, guess int) float64 {
        actual := g.player.Evaluate(input)
        distance := abs(guess - actual)
        if distance == 0 {
                return 1.0
        }

        ratio := float64(distance) / float64(math.MaxInt32)

        return 1.0 - ratio
}

func NewStackMachineScorerWithPlayer(player *StackMachinePlayer) *StackMachineScorer {
        return &StackMachineScorer{player: player}
}

func abs(i int) int {
        if i < 0 {
                return -i
        }
        return i
}

```


and that's it for today. We have ourselves a player with genes and a way to evaluate the player's fitness against a secret function known only to the scorekeeper.
Next time I pick this up, I'll be ready to implement more of the game logic and evolution system.
