---
title: "Pointing to offer"
date: 2020-04-03T01:37:56+08:00
lastmod: 2020-04-03T01:37:56+08:00
draft: false
tags: ["algorithm"]
categories: ["Chinese","algorithm"]
author: "xiantang"
---




## No2 Singleton Pattern

```java
class No2TwiceCheckSingleton {
    private volatile static No2TwiceCheckSingleton instance = null;
    private static final Object sybObj = new Object();

  // 一定记住要私有化构造器，不然人家还是能够创建
    private No2TwiceCheckSingleton() {
    }

    static No2TwiceCheckSingleton getInstance() {
        if (instance == null) {
            synchronized (sybObj) {
                if (instance == null) {
                    instance = new No2TwiceCheckSingleton();
                }
            }
        }

        return instance;
    }
}
```

## No3 Find the duplicate number

![image-20200401174837347](https://tva1.sinaimg.cn/large/00831rSTly1gdeeud3so4j314i0aa7nj.jpg)

```java
public class No3FindDupNum {
    public static boolean find(int[] nums) {
        for (int i = 0; i < nums.length; i++) {
            // 确保当前索引下的是对的
            while (nums[i] != i) {
                // 如果相等说明已经重复了
                if (nums[nums[i]] == nums[i]) {
                    return true;
                }
                // 当前的
                int num = nums[i];
                // 当前所在索引的
                int num1 = nums[num];
                // 交换
                nums[i] = num1;
                nums[num] = num;
            }
        }
        return false;
    }
}

```

If we rearrange {2,3,1,0,2,5,3}, its sorted position will become {0,1,2,2,3,3,5} that is, some numbers are not on their corresponding index, i.e., nums[i] != i. We can do this, traverse the entire list to ensure that each corresponding value is its index, if it is not the corresponding index, then swap the corresponding value until the current value is the corresponding index, where encountering the value under its own index equals the corresponding value will return true indicating that it has been found.

## No 3 Find the duplicate number without modifying the array

![image-20200401185303988](https://tva1.sinaimg.cn/large/00831rSTly1gdegpd0txkj314q0aeh47.jpg)

```java
class No4FindDupNumUnModify {
    static boolean findUnmodified(int[] nums) {
        int length = nums.length;
        int[] another = new int[length];
        Arrays.fill(another, -1);
        for (int num : nums) {
            if (another[num] == num) {
                return true;
            } else {
                another[num] = num;
            }

        }
        return false;
    }
}
```

Use an array to copy this array, the length is the same, check if it exists when it is released.

## No4 Find in a two-dimensional array

![image-20200401185939762](https://tva1.sinaimg.cn/large/00831rSTly1gdegw890cfj314m05odor.jpg)

```java
public class No5FindInTwoMatrixArray {
    public static boolean find(int[][] arr,int target) {
        int a = arr.length;
        int b = arr[0].length;
        int i = 0;
        int j = b - 1;
        while (i < a && j >= 0) {
            if (arr[i][j] == target) {
                return true;
            } else if (arr[j][i] > target) {
                j--;
            } else {
                i++;
            }

        }
        return false;
    }
}
```

```java
{
{1, 2, 8, 9},
{2, 4, 9, 12},
{4, 7, 10, 13},
{6, 8, 11, 15}
}
```

We can easily find that the number below 9 is greater than 9, and the number to the left of 9 is less than 9

So if we want to find a value, we can start from the upper right corner. Because the target number is 7 less than 9, we can exclude the numbers below 9.

```java
{
{1, 2, 8},
{2, 4, 9},
{4, 7, 10},
{6, 8, 11}
}
```

Start investigating from 8 below, the same as 9, excluding the data below 8

```java
{
{1, 2},
{2, 4},
{4, 7},
{6, 8}
}
```

Start investigating from 2 because 7 is greater than 2, so exclude the data to the left of 2

```java
{
{2, 4},
{4, 7},
{6, 8}
}
```

And so on, until the number in the upper right corner equals 7.

## No5 Replace Spaces

![image-20200401191220574](https://tva1.sinaimg.cn/large/00831rSTly1gdeh9f2aqnj314i04c44n.jpg)

```java
class No6ReplaceSpace {
    static String replace(String s) {
        int spaceCount = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == ' ') {
                spaceCount += 1;
            }
        }
        int newLength = s.length() + spaceCount * 2;
        char[] newString = new char[newLength];
        int cur = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == ' ') {

                newString[cur] = '%';
                cur += 1;
                newString[cur] = '2';
                cur += 1;
                newString[cur] = '0';
                cur += 1;
            } else {
                char c = s.charAt(i);
                newString[cur] = c;
                cur += 1;
            }
        }

        return new String(newString);
    }
}

```

The method is relatively simple, with a time complexity of O(n). First, traverse the string, then find the space, calculate the length required by the space, and build an array with this length. Then go down and fill in the corresponding values at the corresponding positions, and maintain a cur pointer.

## No6 Print the linked list from the end

```java
public class No7PrintLinkedListFromTail {
    public static void print(Node root) {
        if (root != null) {
            print(root.next);
            System.out.println(root.data);
        }

    }
```

There's nothing to say about using backtracking.

```java
public class No7PrintLinkedListFromTail {
    static void printUseStack(Node root) {
        Stack<Node> nodes = new Stack<>();
        while (root != null) {
            nodes.push(root);
            root = root.next;
        }
        while (!nodes.isEmpty()) {
            System.out.println(nodes.pop().data);
        }
    }
}

```

Use the stack, pay attention to the boundary, there's nothing to say.

The stack and recursion are the same.

## No7 Rebuild Binary Tree

![image-20200401200402633](https://tva1.sinaimg.cn/large/00831rSTly1gdeir7rlk0j314u07wtks.jpg)

```java
class No8RebuildBinaryTree {
    static TreeNode rebuild(int[] preOrder, int[] midOrder) {
        if (preOrder.length == 0 || midOrder.length == 0) {
            return null;
        }
        int rootVal = preOrder[0];
        TreeNode root = new TreeNode(rootVal);
        int cutIndex = 0;
        for (int i = 0; i < midOrder.length; i++) {
            int value = midOrder[i];
            if (value == rootVal) {
                cutIndex = i;
            }
        }
        int[] midOrderLeft = Arrays.copyOfRange(midOrder, 0, cutIndex);
        int[] midOrderRight = Arrays.copyOfRange(midOrder, cutIndex + 1, midOrder.length);
        int[] preOrderLeft =  Arrays.copyOfRange(preOrder, 1, 1 + cutIndex);
        int[] preOrderRight = Arrays.copyOfRange(preOrder, preOrder.length -1 - cutIndex, preOrder.length);
        root.left = rebuild(preOrderLeft, midOrderLeft);
        root.right = rebuild(preOrderRight, midOrderRight);
        return root;
    }
}
```

The first element of the pre-order traversal must be the root node 1

We can find the left and right subtrees of the root node 1 in the in-order traversal based on this root node

Left subtree {4,7,2}  Right subtree {5,3,8,6}

You can also find the left and right subtrees of the pre-order traversal based on this

 Left subtree {2,4,7}  Right subtree {3,5,6,8}

You can get the corresponding root nodes 2,3 and continue to recurse

## No8 Next node of the binary tree

![image-20200402110410382](https://tva1.sinaimg.cn/large/00831rSTly1gdf8rre6cjj314q06yguw.jpg)

```java
public class FindNextNodeByMidOrder {

    public static TreeNode find(TreeNode root, int i) {
        List<TreeNode> treeNodes = new ArrayList<>();
        find(root, treeNodes);
        boolean flag = false;
        for (TreeNode treeNode : treeNodes) {
            if (flag) {
                return treeNode;
            } else {
                if (treeNode.data == i) {
                    flag = true;
                }
            }

        }

        return null;
    }

    private static void find(TreeNode root, List<TreeNode> nodes) {

        if (root == null) {
            return;
        }
        find(root.left, nodes);
        nodes.add(root);
        find(root.right, nodes);

    }

}

```

There's not much to say, read the nodes in inorder traversal and then find the next node of the corresponding node.

## No9 Implement a queue with two stacks

![image-20200402110725037](https://tva1.sinaimg.cn/large/00831rSTly1gdf8v34ttfj314q05uwn6.jpg)

```java
class N9Queue<T> {

    private Stack<T> inStack = new Stack<>();
    private Stack<T> outStack = new Stack<>();


    void appendTail(T element) {
        inStack.push(element);
    }

    T deleteHead() {
        if (!outStack.isEmpty()) {
            return outStack.pop();
        } else {
            while (!inStack.isEmpty()) {
                outStack.push(inStack.pop());
            }
            return outStack.pop();
        }
    }
}
```

One is the enqueue stack and the other is the dequeue stack.

No matter what, elements are always put into the dequeue stack.

When taking out elements, there are two situations. Situation 1: The dequeue stack has no elements, read all the data from the enqueue stack into the dequeue stack, and then pop the top element of the stack.

Situation 2: The dequeue stack has elements, directly pop the top element of the stack.

## No10 11 Fibonacci sequence and frog jumping steps

```java
class No10Fibonacci {
    static int fibonacciRecursive(int i) {
        if (i <= 1) {
            return i;
        }

        return fibonacciRecursive(i - 1) + fibonacciRecursive(i - 2);
    }
}
```

Use recursion

![image-20200402132423497](https://tva1.sinaimg.cn/large/00831rSTly1gdfctp8comj30li0c674t.jpg)

It will construct into a binary tree, the time complexity is relatively high, but it is relatively concise, but the interviewer will not like it.

```java
class No10Fibonacci {
      static int fibonacciIteration(int i) {
        int[] fib = new int[i + 1];
        fib[0] = 0;
        fib[1] = 1;
        for (int j = 2; j <= i; j++) {
            fib[j] = fib[j - 1] + fib[j - 2];
        }

        return fib[i];
    }
}

```

The time complexity of using iteration is relatively low, and this recursion can reduce repeated calculations.

## No11 The smallest number in the rotated array

![image-20200402162527648](https://tva1.sinaimg.cn/large/00831rSTly1gdfi1zohzfj314w08cna6.jpg)

```java
public class N11FindMinDigInArray {
    public static int find(int[] array) {
        int start = 0;
        int end = array.length - 1;
        int mid = start;
        while (array[start] > array[end]) {

            if (end - start == 1) {
                return array[end];
            }

            mid = (start + end) / 2;
            int midVal = array[mid];
            if (midVal >= array[start]) {
                start = mid;
            } else if (midVal <= array[end]) {
                end = mid;
            }
        }
        return array[mid];
    }
}

```

First of all, we must affirm that array[start] will be greater than array[end]

Then there are two situations when you get the corresponding midpoint

If the midpoint falls in the previous array

[3,4,5,1,2]

Falls on 5 and satisfies 5 is greater than array[start], so you can move start to mid

[5,1,2]

Falls on 1 and satisfies less than 2, so move end to mid

At this point, only two are left. The minimum value will be the second element.

## No12 Path in the matrix

![image-20200402172029688](https://tva1.sinaimg.cn/large/00831rSTly1gdfjn8zra6j31520dae0z.jpg)

```java
public class No12HasPathInMatrix {
    public static boolean find(char[][] matrix, String str) {
        for (int i = 0; i < matrix.length; i++) {
            for (int j = 0; j < matrix[i].length; j++) {
                int[][] visited = new int[matrix.length][matrix[0].length];
                boolean result = find(matrix, i, j, str,visited);

                if (result) return true;
            }
        }
        return false;
    }

    private static boolean find(char[][] matrix, int i, int j, String str, int[][] visited) {
        if (str.length() == 0) {
            return true;
        }
        char c = str.charAt(0);
        if (i < 0 || j < 0 || i > matrix.length - 1 || j > matrix[0].length - 1 || c != matrix[i][j] || visited[i][j] == 1) {
            return false;
        }
        visited[i][j] = 1;
        return find(matrix, i + 1, j, str.substring(1), visited) || find(matrix, i - 1, j, str.substring(1), visited) || find(matrix, i, j + 1, str.substring(1), visited)
                || find(matrix, i, j -1, str.substring(1), visited);


    }
}
```

Traverse all cells, as the starting point, find all the starting points, and then set off

Judge the boundary condition if it is an empty string is correct

Return false if it exceeds the boundary or has been visited

And look for the corresponding surrounding cells up, down, left, and right, the result of the backtracking is correct as long as one of the remaining paths is correct.

## No18 Delete nodes in the linked list

![image-20200408170055155](https://tva1.sinaimg.cn/large/00831rSTly1gdmgry7df0j314i09849i.jpg)

If you think of deleting a node in a linked list, the first reaction is actually to use a while loop to keep traversing. If you find that the next node is the target node, set the next of the current node as the next of the next node.

![image-20200408171308210](https://tva1.sinaimg.cn/large/00831rSTly1gdmh4mhf0xj30yg052tal.jpg)

That is this way, but there is actually a faster way to implement it.

That is, you can replace the node that needs to be deleted based on the next node of the node that needs to be deleted.

That is to replace the next and data of the next node with the content of the node that needs to be deleted.

![image-20200408171615578](https://tva1.sinaimg.cn/large/00831rSTly1gdmh7v14fsj30ym04e408.jpg)

Then what needs to be noted is the boundary conditions and the situation of deleting the tail node.

The tail node cannot be deleted in this way, so it needs to be implemented by traversal.

```java
package info.xiantang.algorithm.interview;

import info.xiantang.algorithm.offer.offer1.Node;

public class No18DeleteNodeFromLinkedListO1 {
    public static Node delete(Node root, Node target) {

        // 如果这个节点是头节点
        if (target.equals(root)) {
            root = root.next;
            return root;
        }
        // 如果这个节点在中间
        else if (target.next != null) {
            Node next = target.next;
            target.next = next.next;
            target.data = next.data;
            return root;
        }
        // 如果这个节点在末尾
        else {
            Node a = root;
            while (root.next != null) {
                Node next = root.next;
                if (next.equals(target)) {
                    root.next = null;
                    break;
                }
                root = root.next;

            }
            return a;
        }

    }
}
```

## Quick sort (naive implementation)

```java
public class No11Qsort {
      private static void sort(int[] array, int start, int end) {
        if (end - start <= 0) {
            return;
        }
        int midVal = array[start];
        swap(array, start, end);
        int small = start - 1;
        for (int i = start; i < end; i++) {
            if (array[i] < midVal) {
                ++small;
                if (small != i) {
                    swap(array, small, i);
                }
            }
        }
        small++;
        swap(array, small, end);
        sort(array, start, small - 1);
        sort(array, small + 1, end);
    }
}

```

I think the difficulty of quick sort is the in-place partition of the array.

I use a simpler way to deal with it here:

Use the first element as the base element.

For the array [3,4,1,3,5,6,1], we can use the first element as the base to exchange it with the end

Get the array [1,4,1,3,5,6,3]. Then define a small index pointing to the position greater than the base, the initial value is -1

Then traverse from start to the element before end.

If it is less than the critical value and the index is not uniform, exchange elements.

## Print all legal brackets

Here is your translated text:

Give you a number and print all its valid parentheses 1 -> {}

```java
public class PrintAllBrackets {
    public static void print(int count) {
        backtrack(count, 0, 0,"");
    }

    private static void backtrack(int count, int left, int right,String str) {
        if (left == count && right == count) {
            System.out.println(str);
            return;
        }
        if (left < count ) {
            backtrack(count,left+1,right,str+"(");
        }
        if(right < left){
            backtrack(count, left, right + 1, str + ")");
        }
    }
}

```

The left parenthesis is less than count and the right parenthesis is less than the left parenthesis

## Move the negative numbers of an array to the right and the positive numbers to the left

`{-1, 2, 3, -1, 2, 13, 123, -555, -888, 66}` -> `{66,2,3,123,2,13,-1,-555,-888,-1}`

```java
public class NoTempMoveLeftOrRight {
    public static void move(int[] array) {
        int left = 0;
        int right = array.length - 1;
        while (left < right) {
            while (array[left] > 0) {
                left += 1;
            }
            while (array[right] < 0) {
                right -= 1;
            }
            if (left >= right) {
                break;
            }
            int i = array[left];
            array[left] = array[right];
            array[right] = i;

        }
    }
}

```

The most important thing to note is that after two loops, left >= right will cause the final element to be swapped, so you need to use an if to break this loop.

## Find the next number of permutations

Given a positive integer, find the next number of all permutations of this positive integer.

First we have a number

 1 2 3 5 4

And we need to be clear that if a number is from high to low from large to small.

That is 5 4 3 2 1.

Then there will be no permutation larger than him.

So we just need to find the previous permutation

1 2 `3` 5 4

Then we swap 1 2 `4` 5 `3`  Because the area of 5 3 is reversed, we just need to swap the position of 5 3.

That is 1 2 4 3 5

```JAVA
package info.xiantang.algorithm.interview;

public class NoTempFindNextPermute {
    public static int[] find(int[] array) {
        int index = -1;
        int end = array.length - 1;
        for (int i = end; i > 0; i--) {
            if (array[i] > array[i - 1]) {
                index = i - 1;
                break;

            }
        }
        if (index == -1) {
            return null;
        }

        int i = array[index];
        array[index] = array[end];
        array[end] = i;
        index += 1;
        while ( index < end) {
            int i1 = array[index];
            array[index] = array[end];
            array[end] = i1;
            end--;
            index++;
        }
        return array;
    }
}

```

## Binary search

```java
public class NoTempBinarySearch {
    public static int find(int[] array, int target) {
        int left = 0;
        int right = array.length - 1;
        while (left <= right) {
            int mid = (left + right) / 2;
            if (array[mid] == target) {
                return mid;
            }
            if (array[mid] > target) {
                right = mid -1;
            } else {
                left = mid +1;
            }
        }

        return -1;
    }
}

```

My method is very simple, get the values of left and right separately, which are 0 and array.length -1

Then the condition of while is left <= right. It should be noted that in the case of left == right = ture, the mid we calculated is likely to be the value we need, so this boundary condition needs to be considered.

Then calculate mid and see if it is larger than array[mid] or smaller than array[mid]

* Greater than target = 3 mid = 4 [1, 2,3,`4`,5,6,7] We need to set right to mid -1
* Less than target = 6 mid = 4 [1, 2,3,`4`,5,6,7] We need to set left to mid +1

## Robot movement range

![image-20200402175701351](https://tva1.sinaimg.cn/large/00831rSTly1gdfkpcbcddj315009kwhr.jpg)

```java
package info.xiantang.algorithm.interview;

public class N13RobotMoveRangeCount {
    public static int count(int threshold, int rows, int cols) {
        boolean[][] visited = new boolean[rows][cols];
        return count(threshold, 0, 0, visited);
    }

    private static int count(int threshold, int rows, int cols, boolean[][] visited) {
        if (rows > visited.length - 1 || cols > visited[0].length-1 || rows < 0 || cols < 0 || visited[rows][cols]) {
            return 0;
        }
        visited[rows][cols] = true;
        int sum = getSum(rows) + getSum(cols);
        int count = 0;
        if (threshold >= sum) {
            count += 1;
        }
        return count + count(threshold, rows + 1, cols, visited) +
                count(threshold, rows - 1, cols, visited) +
                count(threshold, rows, cols + 1, visited)+
                count(threshold, rows, cols - 1, visited);
    }

    private static int getSum(int i) {
        String s = String.valueOf(i);
        int sum = 0;
        for (int j = 0; j < s.length(); j++) {
            String substring = s.substring(j, j + 1);
            sum += Integer.parseInt(substring);
        }
        return sum;
    }

}

```

Use a visit two-dimensional array to do it. The idea is the same as the previous question, there is nothing to say, next question.

## Multithreaded Printing ABC

```java
package info.xiantang.concurrency.interview;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

public class PrintAbc {

    private static int count = 0;
    static ReentrantLock lock = new ReentrantLock();
    static Condition condition = lock.newCondition();


    public static class AbcPrinter extends Thread {
        private char alpha;

        public AbcPrinter(char alpha) {
            this.alpha = alpha;
        }

        @Override
        public void run() {
            while (true) {
                lock.lock();
                if (count % 3 == alpha - 97) {
                    System.out.println(alpha);
                    count += 1;
                    condition.signalAll();
                } else {
                    try {
                        condition.await();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                lock.unlock();

            }
        }
    }

    public static void main(String[] args) {
        new AbcPrinter('a').start();
        new AbcPrinter('b').start();
        new AbcPrinter('c').start();

    }


}

```

The method I used is ReentrantLock, using a modulo operation to calculate the current letter, and the thread is either waiting or outputting, which improves efficiency. If the print is successful, it will wake up the waiting thread, and the corresponding thread will process it. If the current thread is not the thread that needs to be printed, it will be in a waiting state until the next signalAll();
