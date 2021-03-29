import SwiftGraph
import SwiftUI

struct GraphView: View {
    @ObservedObject var viewModel: GraphViewModel
    @ObservedObject var selection = SelectionHandler()

    @GestureState var portalDragOffset = CGVector.zero
    @GestureState var nodeDragOffset: GraphViewModel.NodeDragInfo?
    @GestureState var lineDragInfo: GraphViewModel.LineDragInfo?
    @GestureState var placeholderNodePosition: CGPoint?

    var body: some View {
        GeometryReader { _ in
            ZStack {
                linesView

                if let info = lineDragInfo {
                    placeholderLineView(info: info)
                }

                // TODO: Figure out TextEditor bug
                if let nodes = viewModel.graph.topologicalSort() {
                    ForEach(nodes) { node in
                        NodeView(viewModel: NodeViewModel(graph: viewModel.graph, node: node), selection: selection)
                            .position(node.position + viewModel.portalPosition + portalDragOffset
                                        + (nodeDragOffset?.id == node.id ? nodeDragOffset?.offset ?? .zero : .zero))
                            .onTapGesture {
                                withAnimation {
                                    selection.toggleNode(node)
                                }
                            }
                            .gesture(
                                LongPressGesture()
                                    .sequenced(before: DragGesture()
                                        .updating($lineDragInfo) { value, state, _ in
                                            state = viewModel.onLongPressDragNode(value, position: node.position)
                                        }
                                        .onEnded { value in
                                            viewModel.onLongPressDragNodeEnd(value, node: node)
                                        }
                                    )
                                    .exclusively(before: DragGesture()
                                        .updating($nodeDragOffset) { value, state, _ in
                                            state = viewModel.onDragNode(value, node: node)
                                        }
                                        .onEnded { value in
                                            node.position += CGVector(dx: value.translation.width,
                                                                      dy: value.translation.height)
                                        }
                                )
                            )
                    }
                }

                if let position = placeholderNodePosition {
                    placeholderNodeView(position: position)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    selection.deselectAllNodes()
                }
            }
            .gesture(
                LongPressGesture()
                    .sequenced(before: DragGesture(minimumDistance: 0)
                        .updating($placeholderNodePosition) { value, state, _ in
                            state = value.location
                        }
                        .onEnded(viewModel.onLongPressPortal))
                    .exclusively(before: DragGesture()
                        .updating($portalDragOffset) { value, state, _ in
                            state = CGVector(dx: value.translation.width, dy: value.translation.height)
                        }
                        .onEnded(viewModel.onDragPortal)
                    )
            )
        }
    }

    var linesView: some View {
        ForEach(viewModel.graph.edgeList(), id: \.self) { edge in
            if let offset = nodeDragOffset {
                Line(from: viewModel.graph.vertexAtIndex(edge.u).position
                        + viewModel.portalPosition + portalDragOffset
                        + (viewModel.graph.vertexAtIndex(edge.u).id == offset.id ? offset.offset : .zero),
                     to: viewModel.graph.vertexAtIndex(edge.v).position
                        + viewModel.portalPosition + portalDragOffset
                        + (viewModel.graph.vertexAtIndex(edge.v).id == offset.id ? offset.offset : .zero))
                    .stroke(Color.primary, lineWidth: 1.8)
            } else {
                Line(from: viewModel.graph.vertexAtIndex(edge.u).position
                        + viewModel.portalPosition + portalDragOffset,
                     to: viewModel.graph.vertexAtIndex(edge.v).position
                        + viewModel.portalPosition + portalDragOffset)
                    .stroke(Color.primary, lineWidth: 1.8)
                    .onLongPressGesture {
                        viewModel.graph.removeEdge(edge)
                        viewModel.objectWillChange.send()
                    }
            }
        }
    }

    func placeholderLineView(info: GraphViewModel.LineDragInfo) -> some View {
        Line(from: info.from, to: info.to)
            .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1.8,
                                                        dash: [10],
                                                        dashPhase: viewModel.linePhase))
            .onAppear {
                withAnimation(Animation.linear.repeatForever(autoreverses: false)) {
                    viewModel.linePhase -= 20
                }
            }
    }

    func placeholderNodeView(position: CGPoint) -> some View {
        NodeView(viewModel: NodeViewModel(graph: viewModel.graph, node: Node()), selection: selection)
            .position(position + viewModel.portalPosition + portalDragOffset)
            .opacity(0.4)
    }
}

 struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(viewModel: GraphViewModel(graph: UnweightedGraph()))
    }
 }
