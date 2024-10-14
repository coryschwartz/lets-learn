---
layout: post
title:  "Machine Learning Part 2"
date:   2024-10-02 17:53:49 +0000
categories: technology ML
---

# Cyber Sex

This is going to be a short one. I don't have a whole lot of time to work on this today, but after about an hour of thinking about it today, I have some basically functional
code for generating the next generation.


In my last post, I indicated that there might be two ways to think about what might constitue a gene/trait in my stack machine game. Should I consider each element in the stack
machine as a gene, or should I consider consider the operation and operand together as a pair?

I don't know which is better, but I decided to move forward with the first apprach. Each element in the stack machine is a gene. This approach is simpler, and it automatically implies
some mutation. If the first parent multiplies by 5, and the second parent adds 6, the child might add 5, or multiply by 6, or any combindation. Since I'm doing this, I'm not going
to have a separate mutation step.

I suspect this is gong to converge on a solution more slowly, so I'll test out the second apprach later. For now, I'm blasting ahead with the simpler first apprach.

# General idea

We have two parents that are, at their core, a list of numbers. Their child will be a list of numbers the same length of its parents.

Since the position of the numbers in the list is important, we want the child to populate it's number list so that each element is the same
as the corresponding element in one of it's parents. We will do this randomly, so about 50% comes from each parent.

For example, we might have two parents parent1, and parent2 who create a child like this. In this example, element 0, 3, and 4 come from
parent1 and element 1 and 2 come from parent2.

```
parent 1: [1, 2, 3, 4, 5]
           |        |  |
child   : [1, 7, 8, 4, 5]
              |  |
parent 2: [6, 7, 8, 9, 10]
```

# Code

This is what that looks like:

```
func StackMachineProcreate(p1, p2 *game.StackMachinePlayer) *game.StackMachinePlayer {
	parent1 := p1.Stack.Copy()
	parent2 := p2.Stack.Copy()
	child := game.NewStack()

	for parent1.Size() > 0 {
		if rand.Intn(2) == 0 {
			child.Push(parent1.Dequeue())
			parent2.Pop()
		} else {
			parent1.Pop()
			child.Push(parent2.Dequeue())
		}
	}

	return game.NewStackMachinePlayerWithStack(child)
}
```

# Changes to the stack machine

As I wrote that, I realized that my stack machine was inadequate.
Obviously, I can't just Pop() off of the parent stacks and Push() them on to the child stack. The child would be in reverse order if
we did that! So I added a Dequeue method to our stack machine. This method removes the first element and returns it.
Oh, and also I added a Size() method so I know when to stop.

So returning to the stack machine we wrote in the previous post, we have these new methods:

```
func (s *stack) Size() int {
	return len(s.elements)
}

func (s *stack) Dequeue() int {
	if len(s.elements) == 0 {
		return 0
	}
	value := s.elements[0]
	s.elements = s.elements[1:]
	return value
}
```


That's all for now. To be continued.
In the next post, I'll write some drama into this code. Who lives? Who dies? Who mates with who? Find out next time.
