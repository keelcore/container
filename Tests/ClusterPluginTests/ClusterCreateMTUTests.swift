//===----------------------------------------------------------------------===//
// Copyright © 2026 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import ContainerResource
import Testing

@testable import ContainerCluster

@Suite("ClusterCreate network flags")
struct ClusterCreateMTUTests {
    @Test func networkAndMTUDefaultToNil() throws {
        let command = try ClusterCreate.parse([])
        #expect(command.network == nil)
        #expect(command.mtu == nil)
    }

    @Test func mtuIsParsed() throws {
        let command = try ClusterCreate.parse(["--mtu", "1500"])
        #expect(command.mtu == 1500)
    }

    @Test func mtuOutsideTheValidRangeIsRejected() {
        let invalid = [String(NetworkMTU.validRange.lowerBound - 1), String(NetworkMTU.validRange.upperBound + 1), "abc"]
        for value in invalid {
            #expect(throws: (any Error).self, "expected \(value) to be rejected") {
                _ = try ClusterCreate.parse(["--mtu", value])
            }
        }
    }

    @Test(arguments: ["backend", "backend,mtu=1500"])
    func networkAcceptsNameAndMTU(spec: String) throws {
        let command = try ClusterCreate.parse(["--network", spec])
        #expect(command.network == spec)
    }

    @Test func networkWithoutMTUCombinesWithMTUFlag() throws {
        let command = try ClusterCreate.parse(["--network", "backend", "--mtu", "1500"])
        #expect(command.network == "backend")
        #expect(command.mtu == 1500)
    }

    @Test(arguments: ["backend,mac=02:42:ac:11:00:02", "backend,alias=api.test", "backend,mtu=1", "backend,bogus=1"])
    func networkRejectsWhatNodesCannotShare(spec: String) {
        #expect(throws: (any Error).self) {
            _ = try ClusterCreate.parse(["--network", spec])
        }
    }

    @Test func mtuInBothPlacesIsRejected() {
        #expect(throws: (any Error).self) {
            _ = try ClusterCreate.parse(["--network", "backend,mtu=1500", "--mtu", "1500"])
        }
    }

    @Test func theMTUOptionBeatsTheNetworkMTUAndTheDefault() throws {
        let command = try ClusterCreate.parse(["--mtu", "1500"])
        #expect(try command.nodeMTU(networkMTU: 1450, defaultMTU: 1400) == 1500)
    }

    @Test func theMTUInTheNetworkOptionBeatsTheNetworkMTUAndTheDefault() throws {
        let command = try ClusterCreate.parse(["--network", "backend,mtu=1500"])
        #expect(try command.nodeMTU(networkMTU: 1450, defaultMTU: 1400) == 1500)
    }

    @Test func withoutAnMTUOptionTheNetworkMTUBeatsTheDefault() throws {
        let command = try ClusterCreate.parse(["--network", "backend"])
        #expect(try command.nodeMTU(networkMTU: 1450, defaultMTU: 1400) == 1450)
    }

    @Test func withoutAnMTUOptionOrNetworkMTUTheDefaultIsUsed() throws {
        let command = try ClusterCreate.parse(["--network", "backend"])
        #expect(try command.nodeMTU(networkMTU: nil, defaultMTU: 1400) == 1400)
    }

    // Without an option the nodes resolve their network and MTU like any other container.
    @Test func withoutAnOptionNoNetworkIsPassed() throws {
        let command = try ClusterCreate.parse([])
        #expect(try command.nodeNetwork(builtin: "default") == nil)
    }

    @Test func aNetworkWithoutAnMTUIsPassedWithoutOne() throws {
        let command = try ClusterCreate.parse(["--network", "backend"])
        #expect(try command.nodeNetwork(builtin: "default") == "backend")
    }

    @Test func theMTUInTheNetworkOptionIsPassed() throws {
        let command = try ClusterCreate.parse(["--network", "backend,mtu=1500"])
        #expect(try command.nodeNetwork(builtin: "default") == "backend,mtu=1500")
    }

    @Test func theMTUOptionIsPassedWithTheNetwork() throws {
        let command = try ClusterCreate.parse(["--network", "backend", "--mtu", "1500"])
        #expect(try command.nodeNetwork(builtin: "default") == "backend,mtu=1500")
    }

    @Test func theMTUOptionAloneUsesTheBuiltinNetwork() throws {
        let command = try ClusterCreate.parse(["--mtu", "1500"])
        #expect(try command.nodeNetwork(builtin: "default") == "default,mtu=1500")
    }

    @Test func theMTUOptionAloneNeedsABuiltinNetwork() throws {
        let command = try ClusterCreate.parse(["--mtu", "1500"])
        #expect(throws: (any Error).self) {
            _ = try command.nodeNetwork(builtin: nil)
        }
    }
}
