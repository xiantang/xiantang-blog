---
title: "剑指offer"
date: 2020-04-03T01:37:56+08:00
lastmod: 2020-04-03T01:37:56+08:00
draft: false
tags: ["算法"]
categories: ["中文","算法"]
author: "xiantang"
---




## No2 单例模式

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

## No3 找到重复的数字

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

如果我们对 {2,3,1,0,2,5,3} 进行重排，他的排序的位置会成为{0,1,2,2,3,3,5} 也就是有些数字是不在他对应的索引上的也就是 nums[i] != i 。 我们可以这样做，遍历整个 list 确保每个对应的值都是他的索引，如果不是对应的索引，就将对应的值进行交换，直到当前值是对应的索引，其中遇到自己索引下的值等于对应的值就会返回 true 表示已经找到。

## No 3 找到重复的数字不修改数组

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

使用一个数组拷贝这个数组，长度相同，放出的时候检查是否存在。

## No4 二维数组中的查找

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

我们可以很轻松的发现，9 下边的数字是大于9的，9 左边的数字是小于9的

所以如果我们要找一个值，我们可以从右上角开始找。因为目标数字是7小于9 可以排除9下边的数字。

```java
{
{1, 2, 8},
{2, 4, 9},
{4, 7, 10},
{6, 8, 11}
}
```

下边从8 开始排查和9一样，排除掉8下边的数据

```java
{
{1, 2},
{2, 4},
{4, 7},
{6, 8}
}
```

从2 开始排查 因为7大于2 所以将2左边的数据排除

```java
{
{2, 4},
{4, 7},
{6, 8}
}
```

以此类推，直到右上角的数字于7相等。

## No5 替换空格

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

做法还算简单，O(n)的时间复杂度，先遍历一遍字符串，然后找出空格，计算出空格需要的长度，建立一个加上这个长度的数组。然后就往下走一个个对应的位置填写对应的数值，并且维护一个 cur 的指针。

## No6 从尾到头打印链表

```java
public class No7PrintLinkedListFromTail {
    public static void print(Node root) {
        if (root != null) {
            print(root.next);
            System.out.println(root.data);
        }

    }
```

使用回溯没啥说的。

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

使用栈，注意边界就行了，没啥说的。

栈和递归一样。

## No7 重建二叉树

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

前序遍历的第一个元素一定是根节点 1

我们可以根据这个根节点找到中序遍历的根节点 1 的左右子树

左子树{4,7,2}  右子树 {5,3,8,6}

又可以根据这个找到前序遍历的左右子树

 左子树{2,4,7}  右子树 {3,5,6,8}

可以分别拿到对应的根节点2,3 继续递归下去

## No8 二叉树的下一个节点

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

没啥说的中序遍历读进nodes 然后找到对应节点的下一个节点

## No9 用两个栈实现队列

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

一个是入队栈一个是出队栈。

放入元素无论如何都是放入到出队栈

取出元素  分为两种情况 情况1 出队栈没有元素，将所有的入队栈中的数据读入出队栈，然后弹出栈顶元素

情况2 出队栈有元素 直接弹出栈顶元素。

## No10 11 斐波那契数列与青蛙跳台阶

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

使用递归的方式

![image-20200402132423497](https://tva1.sinaimg.cn/large/00831rSTly1gdfctp8comj30li0c674t.jpg)

会构造成为一棵二叉树，时间复杂度较高，但是比较简洁，但是面试官不会喜欢。

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

使用迭代的方式时间复杂度较低，使用这个递推能够降低重复的运算。

## No11 旋转数组的最小数字

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

首先我们要肯定一点array[start] 会大于 array[end]

然后取到对应的中点有两种情况

如果中点落在前边的数组

[3,4,5,1,2]

落在5 并且满足 5 大于 array[start] 所以可以将start 移动的mid

[5,1,2]

落在1 并且满足小于2 所以将 end 移动到mid

此时只剩下两个 最小值会是第二个元素。

## No12 矩阵中的路径

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

遍历所有格子，作为起点，找到所有的起点，然后出发

判断边界情况如果是空字符串就是对的

超出边界或者已经访问过返回false

并且查找对应的周围上下左右格子，回溯回来的结果只要有一个剩余路径正确就正确。

## No18 删除链表中的节点

![image-20200408170055155](https://tva1.sinaimg.cn/large/00831rSTly1gdmgry7df0j314i09849i.jpg)

如果想到删除一个链表的节点，第一时间反应过来其实是使用一个 while 循环不断遍历下去，发现下一个节点是目标节点的话就将当前节点的next 设置为下一个节点 next。

![image-20200408171308210](https://tva1.sinaimg.cn/large/00831rSTly1gdmh4mhf0xj30yg052tal.jpg)

 也就是这种方式，但是其实还是有更快的方式来实现。

就是可以根据需要删除的那个节点的下一个节点替换需要删除的节点。

也就是将下一个节点的next 和 data 都替换为需要删除的节点的content。

![image-20200408171615578](https://tva1.sinaimg.cn/large/00831rSTly1gdmh7v14fsj30ym04e408.jpg)

然后需要注意的是边界条件和删除尾节点的情况。

尾节点无法这样删除所以需要通过遍历实现。

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

## 快速排序(朴素实现)

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

我觉得快排的难点在于对于数组的原地切分。

我这边采用比较简单的方式来处理:

使用第一个元素作为基准元素。

对于 [3,4,1,3,5,6,1]的数组，我们可以把第一个元素作为基准将它和end作为交换

得出 [1,4,1,3,5,6,3]的数组。然后定义一个 small 索引指向大于基准的位置 初始值为 -1

然后从start 遍历到 end 前一个元素。

如果小于临界值 并且下标不统一就交换元素。

## 打印所有合法括号

给你一个数字 打印他的所有合法括号 1 -> {}

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

左括号小于count 并且右括号小于左括号

## 将一个数组的负数移到右边 正数移到左边

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

最需要注意的一点是，两个循环后， left >= right 回导致最后的元素进行交换，所以需要用一个if来断开这个循环。

## 寻找全排列的下一个数

给出一个正整数，找出这个正整数所有数字全排列的下一个数。

首先我们有一个数是

 1 2 3 5 4

并且我们要明确一点就是如果是一个数每一位从高到低都是从大打小的话。

也就是 5 4 3 2 1 的话。

那么就不会有比他大的全排列。

所以我们只需要找到全排列的前一位就行了

1 2 `3` 5 4

然后我们交换 1 2 `4` 5 `3`  又因为 5 3 这个区域是逆序的我们只要交换 5 3 的位置即可。

就是 1 2 4 3 5

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

## 二分查找

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

我的做法很简单，分别获取left 和 right 的值 分别是 0 和 array.length -1

然后 while 的条件是 left <= right 需要注意的是在 left == right = ture 的情况下很有可能求出的mid 就是我们所需要的值，所以这个边界情况需要考虑。

然后求出 mid  查看是比array[mid] 大还是比array[mid]小

* 大于 target =  3  mid = 4  [1, 2,3,`4`,5,6,7]  我们就需要将 right  设置为 mid -1
* 小于 target = 6 mid = 4  [1, 2,3,`4`,5,6,7] 我们就需要将left 设置为 mid +1

## 机器人移动范围

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

用一个visit 二位数组来做。和上一题思路一样没啥好说的下一题。

## 多线程打印ABC

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

我采用的是 ReentrantLock 的方式使用一个模运算进行计算当前的字母，并且线程不是在等待就是在输出，提高了效率。打印成功就唤醒等待中的线程，并且对应的线程会进行处理。如果当前线程不是需要打印的线程，就会处于等待状态，直到下一次 signalAll();
