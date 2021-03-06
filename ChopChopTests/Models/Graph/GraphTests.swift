import XCTest
@testable import ChopChop

class GraphTests: XCTestCase {
    struct IntNode: Node {
        let id = UUID()
        var label: Int

        init(_ label: Int) {
            self.label = label
        }
    }

    func makeEmptyGraph(isDirected: Bool) -> Graph<IntNode> {
        let graph = Graph<IntNode>(isDirected: isDirected)
        assert(graph.nodes.isEmpty)
        return graph
    }

    func makeGraphWithNodes(isDirected: Bool, _ nodes: IntNode...) -> Graph<IntNode> {
        let graph = Graph<IntNode>(isDirected: isDirected)

        for node in nodes {
            graph.addNode(node)
        }

        return graph
    }

    func makeGraphWithEdges(isDirected: Bool, _ edges: Edge<IntNode>?...) -> Graph<IntNode> {
        let graph = Graph<IntNode>(isDirected: isDirected)

        for edge in edges {
            if let validEdge = edge {
                try? graph.addEdge(validEdge)
            }
        }

        return graph
    }
}

// MARK: - init
extension GraphTests {
    func testConstruct() {
        let graph = Graph<IntNode>(isDirected: true)

        XCTAssertTrue(graph.nodes.isEmpty, "Graph should initially be empty")
        XCTAssertTrue(graph.edges.isEmpty, "Graph should initially be empty")
    }
}

// MARK: - addNode
extension GraphTests {
    func testAddNode_newNode_success() {
        let addedNode = IntNode(1)

        let graph = makeEmptyGraph(isDirected: true)

        graph.addNode(addedNode)

        XCTAssertTrue(graph.containsNode(addedNode), "Graph should contain added node")
    }

    func testAddNode_existingNode_doNothing() {
        let existingNode = IntNode(1)

        let graph = makeGraphWithNodes(isDirected: true, existingNode)

        graph.addNode(existingNode)

        XCTAssertTrue(graph.containsNode(existingNode), "Graph should contain existing node")
        XCTAssertEqual(graph.nodes.count, 1, "Graph should only contain one node")
    }
}

// MARK: - removeNode
extension GraphTests {
    func testRemoveNode_existingNode_success() {
        let removedNode = IntNode(1)

        let graph = makeGraphWithNodes(isDirected: true, removedNode)

        graph.removeNode(removedNode)

        XCTAssertFalse(graph.containsNode(removedNode), "Graph should not contain removed node")
    }

    func testRemoveNode_graphWithEdges_connectedEdgesRemoved() throws {
        let removedNode = IntNode(1)
        let edgeWithDestinationRemoved = try XCTUnwrap(Edge(source: IntNode(2), destination: removedNode))
        let edgeWithSourceRemoved = try XCTUnwrap(Edge(source: removedNode, destination: IntNode(3)))
        let unconnectedEdge = try XCTUnwrap(Edge(source: IntNode(2), destination: IntNode(3)))

        let graph = makeGraphWithEdges(
            isDirected: true,
            edgeWithDestinationRemoved,
            edgeWithSourceRemoved,
            unconnectedEdge)

        graph.removeNode(removedNode)

        XCTAssertFalse(graph.containsEdge(edgeWithDestinationRemoved), "Connected edge should be removed")
        XCTAssertFalse(graph.containsEdge(edgeWithSourceRemoved), "Connected edge should be removed")
        XCTAssertTrue(graph.containsEdge(unconnectedEdge), "Unconnected edge should not be removed")
    }

    func testRemoveNode_emptyGraph_doNothing() {
        let graph = makeEmptyGraph(isDirected: true)

        graph.removeNode(IntNode(1))

        XCTAssertTrue(graph.nodes.isEmpty, "Graph should still be empty")
    }
}

// MARK: - containsNode
extension GraphTests {
    func testContainsNode_existingNode_returnTrue() {
        let testNode = IntNode(1)

        let graph = makeGraphWithNodes(isDirected: true, testNode)

        XCTAssertTrue(graph.containsNode(testNode), "Graph should contain existing node")
    }

    func testContainsNode_emptyGraph_returnFalse() {
        let graph = makeEmptyGraph(isDirected: true)

        XCTAssertFalse(graph.containsNode(IntNode(1)), "Empty graph should not contain node")
    }
}

// MARK: - addEdge
extension GraphTests {
    func testAddEdge_graphWithNodes_success() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let addedEdge = try XCTUnwrap(Edge(source: source, destination: destination))

        let graph = makeGraphWithNodes(isDirected: true, source, destination)

        try graph.addEdge(addedEdge)

        XCTAssertTrue(graph.containsEdge(addedEdge), "Graph should contain added edge")
    }

    func testAddEdge_graphWithoutNodes_missingNodesAdded() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let addedEdge = try XCTUnwrap(Edge(source: source, destination: destination))

        let graph = makeEmptyGraph(isDirected: true)

        try graph.addEdge(addedEdge)

        XCTAssertTrue(graph.containsEdge(addedEdge), "Graph should contain added edge")
        XCTAssertTrue(graph.containsNode(source), "Graph should contain source of added edge")
        XCTAssertTrue(graph.containsNode(destination), "Graph should contain destination of added edge")
    }

    func testAddEdge_multipleEdgesWithSameSourceAndDestination_success() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let testEdgeA = try XCTUnwrap(Edge(source: source, destination: destination, weight: 1.0))
        let testEdgeB = try XCTUnwrap(Edge(source: source, destination: destination, weight: 2.0))

        let graph = makeGraphWithNodes(isDirected: true, source, destination)

        try graph.addEdge(testEdgeA)
        try graph.addEdge(testEdgeB)

        let expectedEdges = [testEdgeA, testEdgeB]

        XCTAssertEqual(Set(graph.edges), Set(expectedEdges), "Graph should contain all added edges")
    }

    func testAddEdge_undirectedGraph_reverseEdgeAdded() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let addedEdge = try XCTUnwrap(Edge(source: source, destination: destination))
        let reverseEdge = addedEdge.reversed

        let graph = makeGraphWithNodes(isDirected: false, source, destination)

        try graph.addEdge(addedEdge)

        XCTAssertTrue(graph.containsEdge(reverseEdge), "Undirected graph should contain reverse of added edge")
    }

    func testAddEdge_undirectedGraphAddLoop_oneEdgeAdded() throws {
        let node = IntNode(1)
        let loop = try XCTUnwrap(Edge(source: node, destination: node))

        let graph = makeGraphWithNodes(isDirected: false, node)

        try graph.addEdge(loop)

        XCTAssertEqual(graph.edges.count, 1, "Only one edge should be added")
    }
}

// MARK: - removeEdge
extension GraphTests {
    func testRemoveEdge_graphWithEdge_success() throws {
        let removedEdge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))

        let graph = makeGraphWithEdges(isDirected: true, removedEdge)

        graph.removeEdge(removedEdge)

        XCTAssertFalse(graph.containsEdge(removedEdge), "Graph should not contain removed edge")
    }

    func testRemoveEdge_graphWithoutEdge_doNothing() throws {
        let edge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))

        let graph = makeEmptyGraph(isDirected: true)

        graph.removeEdge(edge)

        XCTAssertFalse(graph.containsEdge(edge), "Graph should not contain edge")
    }

    func testRemoveEdge_undirectedGraph_reverseEdgeRemoved() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let removedEdge = try XCTUnwrap(Edge(source: source, destination: destination))
        let reverseEdge = removedEdge.reversed

        let graph = makeGraphWithEdges(isDirected: false, removedEdge)

        graph.removeEdge(removedEdge)

        XCTAssertFalse(graph.containsEdge(reverseEdge), "Undirected graph should not contain reverse of removed edge")
    }
}

// MARK: - containsEdge
extension GraphTests {
    func testContainsEdge_graphWithEdge_returnTrue() throws {
        let existingEdge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))

        let graph = makeGraphWithEdges(isDirected: true, existingEdge)

        XCTAssertTrue(graph.containsEdge(existingEdge), "Graph should contain existing edge")
    }

    func testContainsEdge_graphWithoutEdge_returnFalse() throws {
        let edge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))

        let graph = makeEmptyGraph(isDirected: true)

        XCTAssertFalse(graph.containsEdge(edge), "Graph should not contain edge")
    }

    func testContainsEdge_undirectedGraphWithEdge_containsReverseEdge() throws {
        let existingEdge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))
        let reverseEdge = existingEdge.reversed

        let graph = makeGraphWithEdges(isDirected: false, existingEdge)

        XCTAssertTrue(graph.containsEdge(reverseEdge), "Undirected graph should contain reverse of existing edge")
    }
}

// MARK: - nodes
extension GraphTests {
    func testNodes_graphWithNodes_success() {
        let testNodeA = IntNode(1)
        let testNodeB = IntNode(2)

        let graph = makeGraphWithNodes(isDirected: true, testNodeA, testNodeB)

        let expectedNodes = [testNodeA, testNodeB]

        XCTAssertEqual(Set(graph.nodes), Set(expectedNodes), "All contained nodes should be returned")
    }

    func testNodes_emptyGraph_returnEmptyList() {
        let graph = makeEmptyGraph(isDirected: true)

        XCTAssertTrue(graph.nodes.isEmpty, "Empty graph should contain no nodes")
    }
}

// MARK: - edges
extension GraphTests {
    func testEdges_directedGraph_success() throws {
        let testEdgeA = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))
        let testEdgeB = try XCTUnwrap(Edge(source: IntNode(2), destination: IntNode(3)))
        let testEdgeC = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(3)))

        let graph = makeGraphWithEdges(isDirected: true, testEdgeA, testEdgeB, testEdgeC)

        let expectedEdges = [testEdgeA, testEdgeB, testEdgeC]

        XCTAssertEqual(Set(graph.edges), Set(expectedEdges), "All contained edges should be returned")
    }

    func testEdges_multipleEdgesWithSameSourceAndDestination_success() throws {
        let source = IntNode(1)
        let destination = IntNode(2)
        let testEdgeA = try XCTUnwrap(Edge(source: source, destination: destination, weight: 1.0))
        let testEdgeB = try XCTUnwrap(Edge(source: source, destination: destination, weight: 2.0))

        let graph = makeGraphWithEdges(isDirected: true, testEdgeA, testEdgeB)

        let expectedEdges = [testEdgeA, testEdgeB]

        XCTAssertEqual(Set(graph.edges), Set(expectedEdges), "All contained edges should be returned")
    }

    func testEdges_undirectedGraph_reverseEdgesIncluded() throws {
        let testEdge = try XCTUnwrap(Edge(source: IntNode(1), destination: IntNode(2)))

        let graph = makeGraphWithEdges(isDirected: false, testEdge)

        let expectedEdges = [testEdge, testEdge.reversed]

        XCTAssertEqual(Set(graph.edges), Set(expectedEdges),
                       "All contained edges including reverse edges should be returned")
    }

    func testEdges_emptyGraph_returnEmptyList() {
        let graph = makeEmptyGraph(isDirected: true)

        XCTAssertTrue(graph.edges.isEmpty, "Empty graph should contain no edges")
    }
}
